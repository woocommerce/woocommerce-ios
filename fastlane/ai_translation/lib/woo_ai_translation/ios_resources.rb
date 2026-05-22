# frozen_string_literal: true

require 'digest'
require 'fileutils'

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
    UNIT_SEPARATOR = "␟"

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

      # Read a `.strings` file, transparently decoding UTF-16 (BE/LE) if the
      # source still uses Apple's legacy encoding. Modern Xcode emits UTF-8.
      def parse_file(path)
        bytes = File.binread(path)
        parse(decode(bytes), source_path: path)
      end

      def parse(text, source_path: '<string>')
        pos = 0
        len = text.length
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

        def identifier_start?(ch)
          ch =~ /[A-Za-z_]/
        end

        def read_unquoted_identifier(text, pos, source_path)
          start = pos
          pos += 1 while pos < text.length && text[pos] =~ /[A-Za-z0-9_.\-]/
          raise ParseError, error_at(text, pos, source_path, 'empty identifier') if pos == start

          [text[start...pos], pos]
        end

        def read_block_comment(text, pos, source_path)
          start = pos + 2
          ending = text.index('*/', start)
          raise ParseError, error_at(text, pos, source_path, "unterminated /* comment") if ending.nil?

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

        def decode_escape(ch)
          # Lenient: unknown escapes pass through as the literal char (matches
          # Apple CFPropertyList behaviour). `\U` unicode escapes are rare in
          # genstrings output -- omit until needed; an explicit gate will catch
          # any in-the-wild use during validation.
          ESCAPE_TABLE.fetch(ch, ch)
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
        if unit.comment && !unit.comment.empty?
          out << "/* #{unit.comment} */\n"
        end
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
    end
  end
end
