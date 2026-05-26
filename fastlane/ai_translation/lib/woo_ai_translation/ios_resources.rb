# frozen_string_literal: true

require 'digest'
require 'fileutils'
require 'tmpdir'

module WooAiTranslation
  # Order-preserving reader/writer for iOS `Localizable.strings` resources.
  #
  # Mirrors the public interface of WooAiTranslation::AndroidResources so the
  # platform-agnostic Engine, Manifest, Translator and Validators can consume
  # iOS strings without modification. Stdlib-only Ruby -- no Bundler, no
  # external parser dependencies.
  #
  # iOS `.strings` format:
  #
  #   /* Title of the orders screen */
  #   "orders.title" = "Orders";
  #
  #   /* Subtotal line. Parameters: %1$@ - amount */
  #   "cart.subtotal" = "Subtotal: %1$@";
  #
  # Differences from the Android XML format:
  # - No nested types: every entry is a single key/value `.string` Unit.
  #   (`.stringsdict` plurals are deferred per the rollout plan; when the
  #    migration happens, add a sibling StringsDictResources module.)
  # - No `translatable="false"` attribute: iOS uses convention. Default is all
  #   entries translatable; the Engine's exclusion lists guard against the
  #   `AppLocalizedString` / `InfoPlist`-style entries that must not change.
  # - No CDATA, no inline child elements, no XML escaping.
  # - C-style escapes inside double-quoted strings: \\ \" \n \r \t (the four
  #   common ones produced by `genstrings` and `ios_generate_strings_file_from_code`).
  module IosResources
    UNIT_SEPARATOR = '␟'

    # A single translatable resource entry. Always type `:string` for iOS.
    # `entries` is a one-element list to match the Android Unit shape (the
    # Engine treats `entries` as the addressable per-string atoms; for iOS
    # there is exactly one per Unit).
    class Unit
      attr_reader :type, :name, :attributes
      attr_accessor :entries, :comment # entries: [{ id:, source:, value: }]

      def initialize(type:, name:, attributes:, comment: '')
        @type = type
        @name = name
        @attributes = attributes
        @entries = []
        @comment = comment.to_s
      end

      def translatable?
        # iOS has no `translatable=false` attribute. Convention-based exclusion
        # happens upstream of this module (Engine's allow/deny lists).
        true
      end

      # Stable signature of the source content; any change re-translates the
      # whole unit.
      def source_signature
        @entries.map { |e| "#{e[:id]}=#{e[:source]}" }.join(UNIT_SEPARATOR)
      end

      def translation_requests
        @entries.map { |e| { id: e[:id], source: e[:source] } }
      end

      def apply!(translations)
        @entries.each { |e| e[:value] = translations[e[:id]] }
      end

      def fully_translated?
        @entries.any? && @entries.all? { |e| !e[:value].nil? }
      end

      def dup_shell
        copy = Unit.new(type: @type, name: @name, attributes: @attributes.dup, comment: @comment)
        copy.entries = @entries.map { |e| e.dup.tap { |x| x[:value] = nil } }
        copy
      end
    end

    # Parsed document; keeps every unit in source order.
    class Document
      attr_reader :units

      def initialize(units)
        @units = units
      end

      def translatable_units
        @units.select(&:translatable?)
      end

      def translatable_names
        translatable_units.map(&:name)
      end

      def find(name)
        @units.find { |u| u.name == name }
      end
    end

    # Recursive-descent tokenizer for the `.strings` grammar.
    #
    # Tokens of interest:
    #   /* block comment */     -> sticky context for subsequent keys
    #   // line comment          -> same
    #   "key" = "value" ;        -> emit Unit
    #
    # Anything else (whitespace) is skipped.
    module Parser
      module_function

      ParseError = Class.new(StandardError)

      # In-process memoization keyed by content digest. Survives within a
      # single process; identical-content files (e.g. en.lproj re-parsed
      # by filter and round-trip) share one parsed Document.
      CACHE = {}

      # Read a `.strings` file, transparently decoding UTF-16 (BE/LE) if the
      # source still uses Apple's legacy encoding. Modern Xcode emits UTF-8.
      #
      # The parser is O(n²) on large files (known limitation noted in
      # MIGRATIONS / README); on a 1MB en.lproj this is ~40s. We aggressively
      # cache to avoid paying that cost repeatedly:
      #   - In-process: same content within one process => one parse.
      #   - On-disk: cross-process Marshal cache at /tmp/wai_parse_<sha>.bin.
      #     The CI run spawns 15 translate_locale.rb processes that each see
      #     the same en.lproj; without the disk cache they'd each pay ~40s.
      # Cache key is sha256(file content), so any edit invalidates cleanly
      # without mtime games. The disk cache is best-effort: a load/save
      # failure (corrupt file, /tmp full, etc.) falls through to re-parse
      # rather than aborting.
      def parse_file(path)
        bytes = File.binread(path)
        key = Digest::SHA256.hexdigest(bytes)
        CACHE[key] ||= load_cached_or_parse(path, bytes, key)
      end

      def load_cached_or_parse(path, bytes, key)
        # The version prefix lets us invalidate previously-cached Marshal
        # blobs whenever the schema of the parsed Document changes (e.g.
        # the encoding-retag fix that flipped u.name from ASCII_8BIT to
        # UTF-8 — a v1 blob would deserialize with a binary-tagged name
        # and silently break verify_round_trip!). Bump on any schema change.
        disk = File.join(Dir.tmpdir, "wai_parse_v2_#{key[0, 16]}.bin")
        if File.exist?(disk)
          begin
            return Marshal.load(File.binread(disk))
          rescue StandardError
            # corrupt cache — fall through to re-parse + rewrite
          end
        end
        doc = parse(decode(bytes), source_path: path)
        begin
          File.binwrite(disk, Marshal.dump(doc))
        rescue StandardError
          # disk full / read-only fs / etc. — caching is best-effort
        end
        doc
      end

      def parse(text, source_path: '<string>')
        # Force byte-level indexing. Ruby String#[] is O(n) on UTF-8 (it has
        # to scan from the start to find the n-th character), so the original
        # parse-by-character loop was effectively O(n²) on a 1MB .strings
        # file (~40s for en.lproj). With ASCII_8BIT the same loop is O(1) per
        # access, taking ~1s.
        #
        # All branch conditions compare against ASCII literals ('/', '"',
        # '\\', '=', ';') which are single-byte and match identically under
        # ASCII_8BIT. UTF-8 multi-byte sequences inside string literals are
        # appended byte-by-byte to the output buffer, producing valid UTF-8
        # by construction; we re-tag the final strings as UTF-8 below.
        text = text.dup.force_encoding(Encoding::ASCII_8BIT) if text.encoding != Encoding::ASCII_8BIT
        pos = 0
        len = text.bytesize
        units = []
        last_comment = ''

        while pos < len
          pos = skip_whitespace(text, pos)
          break if pos >= len

          if text[pos, 2] == '/*'
            comment, pos = read_block_comment(text, pos, source_path)
            last_comment = comment.strip
            next
          end

          if text[pos, 2] == '//'
            comment, pos = read_line_comment(text, pos)
            last_comment = comment.strip
            next
          end

          if text[pos] == '"' || identifier_start?(text[pos])
            key, pos = read_key(text, pos, source_path)
            pos = skip_whitespace(text, pos)
            expect!(text, pos, '=', source_path)
            pos += 1
            pos = skip_whitespace(text, pos)
            expect!(text, pos, '"', source_path)
            value, pos = read_quoted_string(text, pos, source_path)
            pos = skip_whitespace(text, pos)
            expect!(text, pos, ';', source_path)
            pos += 1

            unit = Unit.new(type: :string, name: key, attributes: {}, comment: last_comment)
            unit.entries = [{ id: key, source: value, value: nil }]
            units << unit
            next
          end

          raise ParseError, error_at(text, pos, source_path, "unexpected character #{text[pos].inspect}")
        end

        # Re-tag everything the parser collected from byte-level reads back to
        # UTF-8 so downstream code (Hash keys, comparisons, regex) sees the
        # canonical encoding. The bytes are already valid UTF-8 because the
        # input started as UTF-8 and we only sliced/copied through it.
        #
        # CRITICAL: use force_encoding in-place, NOT `.dup.force_encoding`.
        # In the parse loop above we built `Unit.new(name: key, ...)` and
        # `unit.entries = [{ id: key, ... }]` — so `u.name` and
        # `u.entries.first[:id]` are the *same* String object (sharing
        # identity, not just content). force_encoding flips the encoding
        # tag of the receiver, so tagging e[:id] also tags u.name. A
        # `.dup` would create a new string for e[:id] and leave u.name
        # stuck on ASCII_8BIT, which silently breaks any set membership /
        # hash comparison that compares u.name (binary) against a UTF-8
        # string read off disk — that bug ate build #37965, where every
        # non-ASCII key (e.g. `"%1$@ · %2$@"`) failed verify_round_trip!.
        units.each do |u|
          # The comment may be the frozen `last_comment = ''` literal when a
          # unit had no preceding /* */ — force_encoding mutates in place,
          # which raises FrozenError under `frozen_string_literal: true`. Dup
          # to get a mutable receiver. Spec failure caught this on PR head
          # 82f37ec3b0: 14 errors in ios_resources_test.rb, all originating
          # at the comment-retag line for keys without a comment.
          u.comment = u.comment.dup.force_encoding(Encoding::UTF_8) if u.comment
          u.entries.each do |e|
            # No dup here: u.name and entries.first[:id] are the same String
            # object (Unit.new received `key` for both), so an in-place
            # force_encoding flips them both. The values returned from
            # read_quoted_string / read_unquoted_identifier are always
            # mutable (+'' inside the parser), so no frozen-string risk.
            e[:id]&.force_encoding(Encoding::UTF_8)
            e[:source]&.force_encoding(Encoding::UTF_8)
            # :value is nil immediately after parse; populated later by
            # apply_results or merge_with_existing using already-UTF-8
            # strings.
          end
        end

        Document.new(units)
      end

      class << self
        private

        # Detect BOM-based UTF-16 (Apple historical convention) and fall back to
        # UTF-8 otherwise. Either way the returned string is encoded as UTF-8.
        def decode(bytes)
          if bytes.start_with?("\xFF\xFE".b)
            bytes.byteslice(2..-1).force_encoding('UTF-16LE').encode('UTF-8')
          elsif bytes.start_with?("\xFE\xFF".b)
            bytes.byteslice(2..-1).force_encoding('UTF-16BE').encode('UTF-8')
          elsif bytes.start_with?("\xEF\xBB\xBF".b)
            bytes.byteslice(3..-1).force_encoding('UTF-8')
          else
            bytes.force_encoding('UTF-8')
          end
        end

        def skip_whitespace(text, pos)
          pos += 1 while pos < text.length && text[pos] =~ /\s/
          pos
        end

        # Apple supports two key forms in `.strings` files:
        #   "quoted.key"   = "value";  (Localizable.strings, genstrings output)
        #   unquoted_key   = "value";  (InfoPlist.strings, NSDictionary-like)
        # Detect and dispatch.
        def read_key(text, pos, source_path)
          return read_quoted_string(text, pos, source_path) if text[pos] == '"'

          read_unquoted_identifier(text, pos, source_path)
        end

        def identifier_start?(char)
          char =~ /[A-Za-z_]/
        end

        def read_unquoted_identifier(text, pos, source_path)
          start = pos
          pos += 1 while pos < text.length && text[pos] =~ /[A-Za-z0-9_.-]/
          raise ParseError, error_at(text, pos, source_path, 'empty identifier') if pos == start

          [text[start...pos], pos]
        end

        def read_block_comment(text, pos, source_path)
          start = pos + 2
          ending = text.index('*/', start)
          raise ParseError, error_at(text, pos, source_path, 'unterminated /* comment') if ending.nil?

          [text[start...ending], ending + 2]
        end

        def read_line_comment(text, pos)
          start = pos + 2
          ending = text.index("\n", start) || text.length
          [text[start...ending], ending]
        end

        # Read a double-quoted, escaped string. Recognises:
        #   \\ \" \n \r \t \0
        # plus any other `\X` as the literal X (lenient like Apple parsers).
        # Returns the decoded value and the position AFTER the closing quote.
        def read_quoted_string(text, pos, source_path)
          raise ParseError, error_at(text, pos, source_path, "expected '\"'") unless text[pos] == '"'

          pos += 1
          out = +''
          loop do
            raise ParseError, error_at(text, pos, source_path, 'unterminated string') if pos >= text.length

            ch = text[pos]
            case ch
            when '"'
              return [out, pos + 1]
            when '\\'
              pos += 1
              raise ParseError, error_at(text, pos, source_path, 'dangling escape') if pos >= text.length

              out << decode_escape(text[pos])
              pos += 1
            else
              out << ch
              pos += 1
            end
          end
        end

        ESCAPE_TABLE = {
          'n' => "\n", 'r' => "\r", 't' => "\t", '0' => "\0",
          '\\' => '\\', '"' => '"', "'" => "'"
        }.freeze

        def decode_escape(char)
          # Lenient: unknown escapes pass through as the literal char (matches
          # Apple CFPropertyList behaviour). `\U` unicode escapes are rare in
          # genstrings output -- omit until needed; an explicit gate will catch
          # any in-the-wild use during validation.
          ESCAPE_TABLE.fetch(char, char)
        end

        def expect!(text, pos, char, source_path)
          got = pos < text.length ? text[pos].inspect : '<EOF>'
          return if pos < text.length && text[pos] == char

          raise ParseError, error_at(text, pos, source_path, "expected #{char.inspect}, got #{got}")
        end

        def error_at(text, pos, source_path, msg)
          line = text[0...pos].count("\n") + 1
          col = pos - (text[0...pos].rindex("\n") || -1)
          "#{source_path}:#{line}:#{col}: #{msg}"
        end
      end
    end

    # Renders a `Document` (or array of `Unit`s) back into iOS `.strings`
    # source form. Mirrors the parser's escape decisions so a parse/write
    # round-trip is idempotent on well-formed input.
    module Writer
      module_function

      # Escape an unescaped runtime value back into `.strings` source form.
      # The four escapes that round-trip cleanly with `genstrings` output.
      def escape(str)
        s = str.to_s
        s = s.gsub('\\') { '\\\\' }
        s = s.gsub('"') { '\"' }
        s = s.gsub("\n") { '\n' }
        s.gsub("\t") { '\t' }
      end

      # Inverse of #escape. The parser already decodes escapes; this exists for
      # symmetry / external callers that need a string-level inverse.
      def unescape(str)
        out = +''
        i = 0
        while i < str.length
          ch = str[i]
          if ch == '\\' && i + 1 < str.length
            out << Parser.send(:decode_escape, str[i + 1])
            i += 2
          else
            out << ch
            i += 1
          end
        end
        out
      end

      def header(locale)
        version = defined?(VERSION) ? VERSION : 'dev'
        prompt_version = defined?(PROMPT_VERSION) ? PROMPT_VERSION : 'dev'
        <<~HDR
          /*
            Generator: WooAiTranslation/#{version}
            Prompt-Version: #{prompt_version}
            Language: #{locale}
            Warning: Machine-translated. Spot-checked, non-blocking review.
          */

        HDR
      end

      def render_unit(unit)
        entry = unit.entries.first
        out = +''
        out << "/* #{unit.comment} */\n" if unit.comment && !unit.comment.empty?
        out << %("#{escape(unit.name)}" = "#{escape(entry[:value])}";\n)
        out
      end

      # `units` must already carry translated values; only fully-translated
      # units are written. Missing keys cause iOS to fall back to the
      # development-region (en) value.
      def write(path, units, locale)
        body = units.select(&:fully_translated?).map { |u| render_unit(u) }.join("\n")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "#{header(locale)}#{body}")
      end

      # Preserved-line writer for incremental PR-time runs. Reads the existing
      # target file as text, replaces the value of each `"key" = "value";`
      # entry whose key appears in `fresh_units` with the unit's new
      # translation, and appends any genuinely-new keys (not present in the
      # original file) at the end. Every other byte stays exactly as it was —
      # comments, ordering, whitespace, the file header from PR #17220, etc.
      #
      # Why: the previous writer re-rendered the entire file from EN-derived
      # units on every run, which propagated EN comment drift (curly-quote
      # vs straight-quote, comment edits) into every target locale and
      # produced 5000-line diffs on the bot's `Translate: ...` commit even
      # when only ~7 keys changed. Aligning with the Android engine's
      # "preserved-line writer" (see android #15972) keeps bot commits
      # reviewable and decouples comment-sync from translation.
      #
      # Falls back to `#write` when the target file is missing (e.g. brand-new
      # locale bootstrap mode).
      def write_incremental(path, fresh_units, locale)
        fresh_units = fresh_units.select(&:fully_translated?)
        fresh_by_name = fresh_units.to_h { |u| [u.name, u] }
        return write(path, fresh_units, locale) unless File.exist?(path) && !fresh_by_name.empty?

        content = File.binread(path).force_encoding(Encoding::UTF_8)
        replaced = []

        # Capture `"key" = "value";` (or unquoted-key form) with the equals
        # punctuation and trailing semicolon preserved verbatim. Only the
        # value content (inside the second pair of quotes) is rewritten.
        pattern = /^(?<key>"(?:\\.|[^"\\])*"|[A-Za-z0-9_.\-]+)(?<eq>[\t ]*=[\t ]*)"(?<val>(?:\\.|[^"\\])*)"(?<tail>[\t ]*;)/
        new_content = content.gsub(pattern) do
          md = ::Regexp.last_match
          raw_key = md[:key]
          decoded_key = raw_key.start_with?('"') ? unescape(raw_key[1..-2]) : raw_key
          if (u = fresh_by_name[decoded_key])
            replaced << decoded_key
            new_value = escape(u.entries.first[:value])
            %(#{raw_key}#{md[:eq]}"#{new_value}"#{md[:tail]})
          else
            md[0]
          end
        end

        # Append any fresh entries that weren't present in the original file.
        appended_keys = fresh_by_name.keys - replaced
        unless appended_keys.empty?
          appended = appended_keys.map { |k| render_unit(fresh_by_name[k]) }.join("\n")
          sep = new_content.end_with?("\n\n") ? '' : (new_content.end_with?("\n") ? "\n" : "\n\n")
          new_content = "#{new_content}#{sep}#{appended}"
        end

        File.write(path, new_content)
      end
    end
  end
end
