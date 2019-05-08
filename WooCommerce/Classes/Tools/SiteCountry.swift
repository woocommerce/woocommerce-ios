import Foundation
import Yosemite

final class SiteCountry {
    /// ResultsController. Fetches the store country from SiteSetting
    ///
    private lazy var resultsController: ResultsController<StorageSiteSetting> = {
        let storageManager = AppDelegate.shared.storageManager
        let sitePredicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
        let settingCountryPredicate = NSPredicate(format: "settingID ==[c] %@", Constants.countryKey)

        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, settingCountryPredicate])

        let siteIDKeyPath = #keyPath(StorageSiteSetting.siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageSiteSetting.siteID, ascending: false)
        return ResultsController<StorageSiteSetting>(storageManager: storageManager,
                                                     sectionNameKeyPath: siteIDKeyPath,
                                                     matching: compoundPredicate,
                                                     sortedBy: [descriptor])
    }()

    init() {
        configureResultsController()
    }

    private var siteCountry: String? {
        return resultsController.fetchedObjects.first?.value
    }

    /// Returns the name of the country associated with the current store.
    /// The default store country is provided in a format like `HK:KOWLOON`
    /// This methdod will transform `HK:KOWLOON` into `Hong Kong`
    /// Will return nil if it can not figure out a valid country name
    var siteCountryName: String? {
        guard let siteCountryCode = siteCountry,
            let code = siteCountryCode.components(separatedBy: ":").first,
            let countryCode = CountryCode(rawValue: code) else {
                return nil
        }

        return countryCode.readableCountry
    }

    /// Setup: ResultsController
    ///
    private func configureResultsController() {
        try? resultsController.performFetch()
    }
}


// MARK: - Mapping between country codes and readable names
// The country names were extracted from the response to `/wp-json/wc/v3/settings/general`
// The default countries are listed under `woocommerce_default_country`
// in one of the following fomats:
// - `"COUNTRY_CODE": "READABALE_COUNTRY_NAME"
// - `"COUNTRY_CODE:COUNTRY_REGION": "READABLE_COUNTRY_NAME - READABLE_COUNTRY_REGION"
extension SiteCountry {
    enum CountryCode: String, CaseIterable {
        // A
        case AX
        case AF
        case AL
        case DZ
        case AS
        case AD
        case AO
        case AI
        case AQ
        case AG
        case AR
        case AM
        case AW
        case AU
        case AT
        case AZ

        // B
        case BS
        case BH
        case BD
        case BB
        case BY
        case PW
        case BE
        case BZ
        case BJ
        case BM
        case BT
        case BO
        case BQ
        case BA
        case BW
        case BV
        case BR
        case IO
        case VG
        case BN
        case BG
        case BF
        case BI

        // C
        case KH
        case CM
        case CA
        case CV
        case KY
        case CF
        case TD
        case CL
        case CN
        case CX
        case CC
        case CO
        case KM
        case CG
        case CD
        case CK
        case CR
        case HR
        case CU
        case CW
        case CY
        case CZ

        // D
        case DK
        case DJ
        case DM
        case DO

        // E
        case EC
        case EG
        case SV
        case GQ
        case ER
        case EE
        case ET

        // F
        case FK
        case FO
        case FJ
        case FI
        case FR
        case GF
        case PF
        case TF

        // G
        case GA
        case GM
        case GE
        case DE
        case GH
        case GI
        case GR
        case GL
        case GD
        case GP
        case GU
        case GT
        case GG
        case GN
        case GW
        case GY

        // H
        case HT
        case HM
        case HN
        case HK
        case HU

        // I
        case IS
        case IN
        case ID
        case IR
        case IQ
        case IE
        case IM
        case IL
        case IT
        case CI

        // J
        case JM
        case JP
        case JE
        case JO

        // K
        case KZ
        case KE
        case KI
        case KW
        case KG

        // L
        case LA
        case LV
        case LB
        case LS
        case LR
        case LY
        case LI
        case LT
        case LU

        // M
        case MO
        case MK
        case MG
        case MW
        case MY
        case MV
        case ML
        case MT
        case MH
        case MQ
        case MR
        case MU
        case YT
        case MX
        case FM
        case MD
        case MC
        case MN
        case ME
        case MS
        case MA
        case MZ
        case MM

        // N
        case NA
        case NR
        case NP
        case NL
        case NC
        case NZ
        case NI
        case NE
        case NG
        case NU
        case NF
        case KP
        case MP
        case NO

        // O
        case OM

        // P
        case PK
        case PS
        case PA
        case PG
        case PY
        case PE
        case PH
        case PN
        case PL
        case PT
        case PR

        // Q
        case QA

        // R
        case RE
        case RO
        case RU
        case RW

        // S
        case ST
        case BL
        case SH
        case KN
        case LC
        case SX
        case MF
        case PM
        case VC
        case WS
        case SM
        case SA
        case SN
        case RS
        case SC
        case SL
        case SG
        case SK
        case SI
        case SB
        case SO
        case ZA
        case GS
        case KR
        case SS
        case ES
        case LK
        case SD
        case SR
        case SJ
        case SZ
        case SE
        case CH
        case SY

        // T
        case TW
        case TJ
        case TZ
        case TH
        case TL
        case TG
        case TK
        case TO
        case TT
        case TN
        case TR
        case TM
        case TC
        case TV

        // U
        case UG
        case UA
        case AE
        case GB
        case US
        case UY
        case UZ

        // V
        case VU
        case VA
        case VE
        case VN

        // W
        case WF
        case EH

        // Y
        case YE

        // Z
        case ZM
        case ZW


        var readableCountry: String {
            switch self {
            // A
            case .AX: return "Åland Islands"
            case .AF: return "Afghanistan"
            case .AL: return "Albania"
            case .DZ: return "Algeria"
            case .AS: return "American Samoa"
            case .AD: return "Andorra"
            case .AO: return "Angola"
            case .AI: return "Anguilla"
            case .AQ: return "Antarctica"
            case .AG: return "Antigua and Barbuda"
            case .AR: return "Argentina"
            case .AM: return "Armenia"
            case .AW: return "Aruba"
            case .AU: return "Australia"
            case .AT: return "Austria"
            case .AZ: return "Azerbaijan"

            // B
            case .BS: return "Bahamas"
            case .BH: return "Bahrain"
            case .BD: return "Bangladesh"
            case .BB: return "Barbados"
            case .BY: return "Belarus"
            case .PW: return "Belau"
            case .BE: return "Belgium"
            case .BZ: return "Belize"
            case .BJ: return "Benin"
            case .BM: return "Bermuda"
            case .BT: return "Bhutan"
            case .BO: return "Bolivia"
            case .BQ: return "Bonaire, Saint Eustatius and Saba"
            case .BA: return "Bosnia and Herzegovina"
            case .BW: return "Botswana"
            case .BV: return "Bouvet Island"
            case .BR: return "Brazil"
            case .IO: return "British Indian Ocean Territory"
            case .VG: return "British Virgin Islands"
            case .BN: return "Brunei"
            case .BG: return "Bulgaria"
            case .BF: return "Burkina Faso"
            case .BI: return "Burundi"

            // C
            case .KH: return "Cambodia"
            case .CM: return "Cameroon"
            case .CA: return "Canada"
            case .CV: return "Cape Verde"
            case .KY: return "Cayman Islands"
            case .CF: return "Central African Republic"
            case .TD: return "Chad"
            case .CL: return "Chile"
            case .CN: return "China"
            case .CX: return "Christmas Island"
            case .CC: return "Cocos (Keeling) Islands"
            case .CO: return "Colombia"
            case .KM: return "Comoros"
            case .CG: return "Congo (Brazzaville)"
            case .CD: return "Congo (Kinshasa)"
            case .CK: return "Cook Islands"
            case .CR: return "Costa Rica"
            case .HR: return "Croatia"
            case .CU: return "Cuba"
            case .CW: return "Curacao"
            case .CY: return "Cyprus"
            case .CZ: return "Czech Republic"

            // D
            case .DK: return "Denmark"
            case .DJ: return "Djibouti"
            case .DM: return "Dominica"
            case .DO: return "Dominican Republic"

            // E
            case .EC: return "Ecuador"
            case .EG: return "Egypt"
            case .SV: return "El Salvador"
            case .GQ: return "Equatorial Guinea"
            case .ER: return "Eritrea"
            case .EE: return "Estonia"
            case .ET: return "Ethiopia"

            // F
            case .FK: return "Falkland Islands"
            case .FO: return "Faroe Islands"
            case .FJ: return "Fiji"
            case .FI: return "Finland"
            case .FR: return "France"
            case .GF: return "French Guiana"
            case .PF: return "French Polynesia"
            case .TF: return "French Southern Territories"

            // G
            case .GA: return "Gabon"
            case .GM: return "Gambia"
            case .GE: return "Georgia"
            case .DE: return "Germany"
            case .GH: return "Ghana"
            case .GI: return "Gibraltar"
            case .GR: return "Greece"
            case .GL: return "Greenland"
            case .GD: return "Grenada"
            case .GP: return "Guadeloupe"
            case .GU: return "Guam"
            case .GT: return "Guatemala"
            case .GG: return "Guernsey"
            case .GN: return "Guinea"
            case .GW: return "Guinea-Bissau"
            case .GY: return "Guyana"

            // H
            case .HT: return "Haiti"
            case .HM: return "Heard Island and McDonald Islands"
            case .HN: return "Honduras"
            case .HK: return "Hong Kong"
            case .HU: return "Hungary"

            // I
            case .IS: return "Iceland"
            case .IN: return "India"
            case .ID: return "Indonesia"
            case .IR: return "Iran"
            case .IQ: return "Iraq"
            case .IE: return "Ireland"
            case .IM: return "Isle of Man"
            case .IL: return "Israel"
            case .IT: return "Italy"
            case .CI: return "Ivory Coast"

            // J
            case .JM: return "Jamaica"
            case .JP: return "Japan"
            case .JE: return "Jersey"
            case .JO: return "Jordan"

            // K
            case .KZ: return "Kazakhstan"
            case .KE: return "Kenya"
            case .KI: return "Kiribati"
            case .KW: return "Kuwait"
            case .KG: return "Kyrgyzstan"

            // L
            case .LA: return "Laos"
            case .LV: return "Latvia"
            case .LB: return "Lebanon"
            case .LS: return "Lesotho"
            case .LR: return "Liberia"
            case .LY: return "Libya"
            case .LI: return "Liechtenstein"
            case .LT: return "Lithuania"
            case .LU: return "Luxembourg"

            // M
            case .MO: return "Macao S.A.R., China"
            case .MK: return "Macedonia"
            case .MG: return "Madagascar"
            case .MW: return "Malawi"
            case .MY: return "Malaysia"
            case .MV: return "Maldives"
            case .ML: return "Mali"
            case .MT: return "Malta"
            case .MH: return "Marshall Islands"
            case .MQ: return "Martinique"
            case .MR: return "Mauritania"
            case .MU: return "Mauritius"
            case .YT: return "Mayotte"
            case .MX: return "Mexico"
            case .FM: return "Micronesia"
            case .MD: return "Moldova"
            case .MC: return "Monaco"
            case .MN: return "Mongolia"
            case .ME: return "Montenegro"
            case .MS: return "Montserrat"
            case .MA: return "Morocco"
            case .MZ: return "Mozambique"
            case .MM: return "Myanmar"

            // N
            case .NA: return "Namibia"
            case .NR: return "Nauru"
            case .NP: return "Nepal"
            case .NL: return "Netherlands"
            case .NC: return "New Caledonia"
            case .NZ: return "New Zealand"
            case .NI: return "Nicaragua"
            case .NE: return "Niger"
            case .NG: return "Nigeria"
            case .NU: return "Niue"
            case .NF: return "Norfolk Island"
            case .KP: return "North Korea"
            case .MP: return "Northern Mariana Islands"
            case .NO: return "Norway"

            // O
            case .OM: return "Oman"

            // P
            case .PK: return "Pakistan"
            case .PS: return "Palestinian Territory"
            case .PA: return "Panama"
            case .PG: return "Papua New Guinea"
            case .PY: return "Paraguay"
            case .PE: return "Peru"
            case .PH: return "Philippines"
            case .PN: return "Pitcairn"
            case .PL: return "Poland"
            case .PT: return "Portugal"
            case .PR: return "Puerto Rico"

            // Q
            case .QA: return "Qatar"

            // R
            case .RE: return "Reunion"
            case .RO: return "Romania"
            case .RU: return "Russia"
            case .RW: return "Rwanda"

            // S
            case .ST: return "São Tomé and Príncipe"
            case .BL: return "Saint Barthélemy"
            case .SH: return "Saint Helena"
            case .KN: return "Saint Kitts and Nevis"
            case .LC: return "Saint Lucia"
            case .SX: return "Saint Martin (Dutch part)"
            case .MF: return "Saint Martin (French part)"
            case .PM: return "Saint Pierre and Miquelon"
            case .VC: return "Saint Vincent and the Grenadines"
            case .WS: return "Samoa"
            case .SM: return "San Marino"
            case .SA: return "Saudi Arabia"
            case .SN: return "Senegal"
            case .RS: return "Serbia"
            case .SC: return "Seychelles"
            case .SL: return "Sierra Leone"
            case .SG: return "Singapore"
            case .SK: return "Slovakia"
            case .SI: return "Slovenia"
            case .SB: return "Solomon Islands"
            case .SO: return "Somalia"
            case .ZA: return "South Africa"
            case .GS: return "South Georgia/Sandwich Islands"
            case .KR: return "South Korea"
            case .SS: return "South Sudan"
            case .ES: return "Spain"
            case .LK: return "Sri Lanka"
            case .SD: return "Sudan"
            case .SR: return "Suriname"
            case .SJ: return "Svalbard and Jan Mayen"
            case .SZ: return "Swaziland"
            case .SE: return "Sweden"
            case .CH: return "Switzerland"
            case .SY: return "Syria"

            // T
            case .TW: return "Taiwan"
            case .TJ: return "Tajikistan"
            case .TZ: return "Tanzania"
            case .TH: return "Thailand"
            case .TL: return "Timor-Leste"
            case .TG: return "Togo"
            case .TK: return "Tokelau"
            case .TO: return "Tonga"
            case .TT: return "Trinidad and Tobago"
            case .TN: return "Tunisia"
            case .TR: return "Turkey"
            case .TM: return "Turkmenistan"
            case .TC: return "Turks and Caicos Islands"
            case .TV: return "Tuvalu"

            // U
            case .UG: return "Uganda"
            case .UA: return "Ukraine"
            case .AE: return "United Arab Emirates"
            case .GB: return "United Kingdom"
            case .US: return "United States"
            case .UY: return "Uruguay"
            case .UZ: return "Uzbekistan"

            // V
            case .VU: return "Vanuatu"
            case .VA: return "Vatican"
            case .VE: return "Venezuela"
            case .VN: return "Vietnam"

            // W
            case .WF: return "Wallis and Futuna"
            case .EH: return "Western Sahara"

            // Y
            case .YE: return "Yemen"

            // Z
            case .ZM: return "Zambia"
            case .ZW: return "Zimbabwe"
            }
        }
        var localisedReadableCountry: String {
            switch self {
            // A
            case .AX: return NSLocalizedString("Åland Islands", comment: "Country name")
            case .AF: return NSLocalizedString("Afghanistan", comment: "Country name")
            case .AL: return NSLocalizedString("Albania", comment: "Country name")
            case .DZ: return NSLocalizedString("Algeria", comment: "Country name")
            case .AS: return NSLocalizedString("American Samoa", comment: "Country name")
            case .AD: return NSLocalizedString("Andorra", comment: "Country name")
            case .AO: return NSLocalizedString("Angola", comment: "Country name")
            case .AI: return NSLocalizedString("Anguilla", comment: "Country name")
            case .AQ: return NSLocalizedString("Antarctica", comment: "Country name")
            case .AG: return NSLocalizedString("Antigua and Barbuda", comment: "Country name")
            case .AR: return NSLocalizedString("Argentina", comment: "Country name")
            case .AM: return NSLocalizedString("Armenia", comment: "Country name")
            case .AW: return NSLocalizedString("Aruba", comment: "Country name")
            case .AU: return NSLocalizedString("Australia", comment: "Country name")
            case .AT: return NSLocalizedString("Austria", comment: "Country name")
            case .AZ: return NSLocalizedString("Azerbaijan", comment: "Country name")

            // B
            case .BS: return NSLocalizedString("Bahamas", comment: "Country name")
            case .BH: return NSLocalizedString("Bahrain", comment: "Country name")
            case .BD: return NSLocalizedString("Bangladesh", comment: "Country name")
            case .BB: return NSLocalizedString("Barbados", comment: "Country name")
            case .BY: return NSLocalizedString("Belarus", comment: "Country name")
            case .PW: return NSLocalizedString("Belau", comment: "Country name")
            case .BE: return NSLocalizedString("Belgium", comment: "Country name")
            case .BZ: return NSLocalizedString("Belize", comment: "Country name")
            case .BJ: return NSLocalizedString("Benin", comment: "Country name")
            case .BM: return NSLocalizedString("Bermuda", comment: "Country name")
            case .BT: return NSLocalizedString("Bhutan", comment: "Country name")
            case .BO: return NSLocalizedString("Bolivia", comment: "Country name")
            case .BQ: return NSLocalizedString("Bonaire, Saint Eustatius and Saba", comment: "Country name")
            case .BA: return NSLocalizedString("Bosnia and Herzegovina", comment: "Country name")
            case .BW: return NSLocalizedString("Botswana", comment: "Country name")
            case .BV: return NSLocalizedString("Bouvet Island", comment: "Country name")
            case .BR: return NSLocalizedString("Brazil", comment: "Country name")
            case .IO: return NSLocalizedString("British Indian Ocean Territory", comment: "Country name")
            case .VG: return NSLocalizedString("British Virgin Islands", comment: "Country name")
            case .BN: return NSLocalizedString("Brunei", comment: "Country name")
            case .BG: return NSLocalizedString("Bulgaria", comment: "Country name")
            case .BF: return NSLocalizedString("Burkina Faso", comment: "Country name")
            case .BI: return NSLocalizedString("Burundi", comment: "Country name")

            // C
            case .KH: return NSLocalizedString("Cambodia", comment: "Country name")
            case .CM: return NSLocalizedString("Cameroon", comment: "Country name")
            case .CA: return NSLocalizedString("Canada", comment: "Country name")
            case .CV: return NSLocalizedString("Cape Verde", comment: "Country name")
            case .KY: return NSLocalizedString("Cayman Islands", comment: "Country name")
            case .CF: return NSLocalizedString("Central African Republic", comment: "Country name")
            case .TD: return NSLocalizedString("Chad", comment: "Country name")
            case .CL: return NSLocalizedString("Chile", comment: "Country name")
            case .CN: return NSLocalizedString("China", comment: "Country name")
            case .CX: return NSLocalizedString("Christmas Island", comment: "Country name")
            case .CC: return NSLocalizedString("Cocos (Keeling) Islands", comment: "Country name")
            case .CO: return NSLocalizedString("Colombia", comment: "Country name")
            case .KM: return NSLocalizedString("Comoros", comment: "Country name")
            case .CG: return NSLocalizedString("Congo (Brazzaville)", comment: "Country name")
            case .CD: return NSLocalizedString("Congo (Kinshasa)", comment: "Country name")
            case .CK: return NSLocalizedString("Cook Islands", comment: "Country name")
            case .CR: return NSLocalizedString("Costa Rica", comment: "Country name")
            case .HR: return NSLocalizedString("Croatia", comment: "Country name")
            case .CU: return NSLocalizedString("Cuba", comment: "Country name")
            case .CW: return NSLocalizedString("Curacao", comment: "Country name")
            case .CY: return NSLocalizedString("Cyprus", comment: "Country name")
            case .CZ: return NSLocalizedString("Czech Republic", comment: "Country name")

            // D
            case .DK: return NSLocalizedString("Denmark", comment: "Country name")
            case .DJ: return NSLocalizedString("Djibouti", comment: "Country name")
            case .DM: return NSLocalizedString("Dominica", comment: "Country name")
            case .DO: return NSLocalizedString("Dominican Republic", comment: "Country name")

            // E
            case .EC: return NSLocalizedString("Ecuador", comment: "Country name")
            case .EG: return NSLocalizedString("Egypt", comment: "Country name")
            case .SV: return NSLocalizedString("El Salvador", comment: "Country name")
            case .GQ: return NSLocalizedString("Equatorial Guinea", comment: "Country name")
            case .ER: return NSLocalizedString("Eritrea", comment: "Country name")
            case .EE: return NSLocalizedString("Estonia", comment: "Country name")
            case .ET: return NSLocalizedString("Ethiopia", comment: "Country name")

            // F
            case .FK: return NSLocalizedString("Falkland Islands", comment: "Country name")
            case .FO: return NSLocalizedString("Faroe Islands", comment: "Country name")
            case .FJ: return NSLocalizedString("Fiji", comment: "Country name")
            case .FI: return NSLocalizedString("Finland", comment: "Country name")
            case .FR: return NSLocalizedString("France", comment: "Country name")
            case .GF: return NSLocalizedString("French Guiana", comment: "Country name")
            case .PF: return NSLocalizedString("French Polynesia", comment: "Country name")
            case .TF: return NSLocalizedString("French Southern Territories", comment: "Country name")

            // G
            case .GA: return NSLocalizedString("Gabon", comment: "Country name")
            case .GM: return NSLocalizedString("Gambia", comment: "Country name")
            case .GE: return NSLocalizedString("Georgia", comment: "Country name")
            case .DE: return NSLocalizedString("Germany", comment: "Country name")
            case .GH: return NSLocalizedString("Ghana", comment: "Country name")
            case .GI: return NSLocalizedString("Gibraltar", comment: "Country name")
            case .GR: return NSLocalizedString("Greece", comment: "Country name")
            case .GL: return NSLocalizedString("Greenland", comment: "Country name")
            case .GD: return NSLocalizedString("Grenada", comment: "Country name")
            case .GP: return NSLocalizedString("Guadeloupe", comment: "Country name")
            case .GU: return NSLocalizedString("Guam", comment: "Country name")
            case .GT: return NSLocalizedString("Guatemala", comment: "Country name")
            case .GG: return NSLocalizedString("Guernsey", comment: "Country name")
            case .GN: return NSLocalizedString("Guinea", comment: "Country name")
            case .GW: return NSLocalizedString("Guinea-Bissau", comment: "Country name")
            case .GY: return NSLocalizedString("Guyana", comment: "Country name")

            // H
            case .HT: return NSLocalizedString("Haiti", comment: "Country name")
            case .HM: return NSLocalizedString("Heard Island and McDonald Islands", comment: "Country name")
            case .HN: return NSLocalizedString("Honduras", comment: "Country name")
            case .HK: return NSLocalizedString("Hong Kong", comment: "Country name")
            case .HU: return NSLocalizedString("Hungary", comment: "Country name")

            // I
            case .IS: return NSLocalizedString("Iceland", comment: "Country name")
            case .IN: return NSLocalizedString("India", comment: "Country name")
            case .ID: return NSLocalizedString("Indonesia", comment: "Country name")
            case .IR: return NSLocalizedString("Iran", comment: "Country name")
            case .IQ: return NSLocalizedString("Iraq", comment: "Country name")
            case .IE: return NSLocalizedString("Ireland", comment: "Country name")
            case .IM: return NSLocalizedString("Isle of Man", comment: "Country name")
            case .IL: return NSLocalizedString("Israel", comment: "Country name")
            case .IT: return NSLocalizedString("Italy", comment: "Country name")
            case .CI: return NSLocalizedString("Ivory Coast", comment: "Country name")

            // J
            case .JM: return NSLocalizedString("Jamaica", comment: "Country name")
            case .JP: return NSLocalizedString("Japan", comment: "Country name")
            case .JE: return NSLocalizedString("Jersey", comment: "Country name")
            case .JO: return NSLocalizedString("Jordan", comment: "Country name")

            // K
            case .KZ: return NSLocalizedString("Kazakhstan", comment: "Country name")
            case .KE: return NSLocalizedString("Kenya", comment: "Country name")
            case .KI: return NSLocalizedString("Kiribati", comment: "Country name")
            case .KW: return NSLocalizedString("Kuwait", comment: "Country name")
            case .KG: return NSLocalizedString("Kyrgyzstan", comment: "Country name")

            // L
            case .LA: return NSLocalizedString("Laos", comment: "Country name")
            case .LV: return NSLocalizedString("Latvia", comment: "Country name")
            case .LB: return NSLocalizedString("Lebanon", comment: "Country name")
            case .LS: return NSLocalizedString("Lesotho", comment: "Country name")
            case .LR: return NSLocalizedString("Liberia", comment: "Country name")
            case .LY: return NSLocalizedString("Libya", comment: "Country name")
            case .LI: return NSLocalizedString("Liechtenstein", comment: "Country name")
            case .LT: return NSLocalizedString("Lithuania", comment: "Country name")
            case .LU: return NSLocalizedString("Luxembourg", comment: "Country name")

            // M
            case .MO: return NSLocalizedString("Macao S.A.R., China", comment: "Country name")
            case .MK: return NSLocalizedString("Macedonia", comment: "Country name")
            case .MG: return NSLocalizedString("Madagascar", comment: "Country name")
            case .MW: return NSLocalizedString("Malawi", comment: "Country name")
            case .MY: return NSLocalizedString("Malaysia", comment: "Country name")
            case .MV: return NSLocalizedString("Maldives", comment: "Country name")
            case .ML: return NSLocalizedString("Mali", comment: "Country name")
            case .MT: return NSLocalizedString("Malta", comment: "Country name")
            case .MH: return NSLocalizedString("Marshall Islands", comment: "Country name")
            case .MQ: return NSLocalizedString("Martinique", comment: "Country name")
            case .MR: return NSLocalizedString("Mauritania", comment: "Country name")
            case .MU: return NSLocalizedString("Mauritius", comment: "Country name")
            case .YT: return NSLocalizedString("Mayotte", comment: "Country name")
            case .MX: return NSLocalizedString("Mexico", comment: "Country name")
            case .FM: return NSLocalizedString("Micronesia", comment: "Country name")
            case .MD: return NSLocalizedString("Moldova", comment: "Country name")
            case .MC: return NSLocalizedString("Monaco", comment: "Country name")
            case .MN: return NSLocalizedString("Mongolia", comment: "Country name")
            case .ME: return NSLocalizedString("Montenegro", comment: "Country name")
            case .MS: return NSLocalizedString("Montserrat", comment: "Country name")
            case .MA: return NSLocalizedString("Morocco", comment: "Country name")
            case .MZ: return NSLocalizedString("Mozambique", comment: "Country name")
            case .MM: return NSLocalizedString("Myanmar", comment: "Country name")

            // N
            case .NA: return NSLocalizedString("Namibia", comment: "Country name")
            case .NR: return NSLocalizedString("Nauru", comment: "Country name")
            case .NP: return NSLocalizedString("Nepal", comment: "Country name")
            case .NL: return NSLocalizedString("Netherlands", comment: "Country name")
            case .NC: return NSLocalizedString("New Caledonia", comment: "Country name")
            case .NZ: return NSLocalizedString("New Zealand", comment: "Country name")
            case .NI: return NSLocalizedString("Nicaragua", comment: "Country name")
            case .NE: return NSLocalizedString("Niger", comment: "Country name")
            case .NG: return NSLocalizedString("Nigeria", comment: "Country name")
            case .NU: return NSLocalizedString("Niue", comment: "Country name")
            case .NF: return NSLocalizedString("Norfolk Island", comment: "Country name")
            case .KP: return NSLocalizedString("North Korea", comment: "Country name")
            case .MP: return NSLocalizedString("Northern Mariana Islands", comment: "Country name")
            case .NO: return NSLocalizedString("Norway", comment: "Country name")

            // O
            case .OM: return NSLocalizedString("Oman", comment: "Country name")

            // P
            case .PK: return NSLocalizedString("Pakistan", comment: "Country name")
            case .PS: return NSLocalizedString("Palestinian Territory", comment: "Country name")
            case .PA: return NSLocalizedString("Panama", comment: "Country name")
            case .PG: return NSLocalizedString("Papua New Guinea", comment: "Country name")
            case .PY: return NSLocalizedString("Paraguay", comment: "Country name")
            case .PE: return NSLocalizedString("Peru", comment: "Country name")
            case .PH: return NSLocalizedString("Philippines", comment: "Country name")
            case .PN: return NSLocalizedString("Pitcairn", comment: "Country name")
            case .PL: return NSLocalizedString("Poland", comment: "Country name")
            case .PT: return NSLocalizedString("Portugal", comment: "Country name")
            case .PR: return NSLocalizedString("Puerto Rico", comment: "Country name")

            // Q
            case .QA: return NSLocalizedString("Qatar", comment: "Country name")

            // R
            case .RE: return NSLocalizedString("Reunion", comment: "Country name")
            case .RO: return NSLocalizedString("Romania", comment: "Country name")
            case .RU: return NSLocalizedString("Russia", comment: "Country name")
            case .RW: return NSLocalizedString("Rwanda", comment: "Country name")

            // S
            case .ST: return NSLocalizedString("São Tomé and Príncipe", comment: "Country name")
            case .BL: return NSLocalizedString("Saint Barthélemy", comment: "Country name")
            case .SH: return NSLocalizedString("Saint Helena", comment: "Country name")
            case .KN: return NSLocalizedString("Saint Kitts and Nevis", comment: "Country name")
            case .LC: return NSLocalizedString("Saint Lucia", comment: "Country name")
            case .SX: return NSLocalizedString("Saint Martin (Dutch part)", comment: "Country name")
            case .MF: return NSLocalizedString("Saint Martin (French part)", comment: "Country name")
            case .PM: return NSLocalizedString("Saint Pierre and Miquelon", comment: "Country name")
            case .VC: return NSLocalizedString("Saint Vincent and the Grenadines", comment: "Country name")
            case .WS: return NSLocalizedString("Samoa", comment: "Country name")
            case .SM: return NSLocalizedString("San Marino", comment: "Country name")
            case .SA: return NSLocalizedString("Saudi Arabia", comment: "Country name")
            case .SN: return NSLocalizedString("Senegal", comment: "Country name")
            case .RS: return NSLocalizedString("Serbia", comment: "Country name")
            case .SC: return NSLocalizedString("Seychelles", comment: "Country name")
            case .SL: return NSLocalizedString("Sierra Leone", comment: "Country name")
            case .SG: return NSLocalizedString("Singapore", comment: "Country name")
            case .SK: return NSLocalizedString("Slovakia", comment: "Country name")
            case .SI: return NSLocalizedString("Slovenia", comment: "Country name")
            case .SB: return NSLocalizedString("Solomon Islands", comment: "Country name")
            case .SO: return NSLocalizedString("Somalia", comment: "Country name")
            case .ZA: return NSLocalizedString("South Africa", comment: "Country name")
            case .GS: return NSLocalizedString("South Georgia/Sandwich Islands", comment: "Country name")
            case .KR: return NSLocalizedString("South Korea", comment: "Country name")
            case .SS: return NSLocalizedString("South Sudan", comment: "Country name")
            case .ES: return NSLocalizedString("Spain", comment: "Country name")
            case .LK: return NSLocalizedString("Sri Lanka", comment: "Country name")
            case .SD: return NSLocalizedString("Sudan", comment: "Country name")
            case .SR: return NSLocalizedString("Suriname", comment: "Country name")
            case .SJ: return NSLocalizedString("Svalbard and Jan Mayen", comment: "Country name")
            case .SZ: return NSLocalizedString("Swaziland", comment: "Country name")
            case .SE: return NSLocalizedString("Sweden", comment: "Country name")
            case .CH: return NSLocalizedString("Switzerland", comment: "Country name")
            case .SY: return NSLocalizedString("Syria", comment: "Country name")

            // T
            case .TW: return NSLocalizedString("Taiwan", comment: "Country name")
            case .TJ: return NSLocalizedString("Tajikistan", comment: "Country name")
            case .TZ: return NSLocalizedString("Tanzania", comment: "Country name")
            case .TH: return NSLocalizedString("Thailand", comment: "Country name")
            case .TL: return NSLocalizedString("Timor-Leste", comment: "Country name")
            case .TG: return NSLocalizedString("Togo", comment: "Country name")
            case .TK: return NSLocalizedString("Tokelau", comment: "Country name")
            case .TO: return NSLocalizedString("Tonga", comment: "Country name")
            case .TT: return NSLocalizedString("Trinidad and Tobago", comment: "Country name")
            case .TN: return NSLocalizedString("Tunisia", comment: "Country name")
            case .TR: return NSLocalizedString("Turkey", comment: "Country name")
            case .TM: return NSLocalizedString("Turkmenistan", comment: "Country name")
            case .TC: return NSLocalizedString("Turks and Caicos Islands", comment: "Country name")
            case .TV: return NSLocalizedString("Tuvalu", comment: "Country name")

            // U
            case .UG: return NSLocalizedString("Uganda", comment: "Country name")
            case .UA: return NSLocalizedString("Ukraine", comment: "Country name")
            case .AE: return NSLocalizedString("United Arab Emirates", comment: "Country name")
            case .GB: return NSLocalizedString("United Kingdom", comment: "Country name")
            case .US: return NSLocalizedString("United States", comment: "Country name")
            case .UY: return NSLocalizedString("Uruguay", comment: "Country name")
            case .UZ: return NSLocalizedString("Uzbekistan", comment: "Country name")

            // V
            case .VU: return NSLocalizedString("Vanuatu", comment: "Country name")
            case .VA: return NSLocalizedString("Vatican", comment: "Country name")
            case .VE: return NSLocalizedString("Venezuela", comment: "Country name")
            case .VN: return NSLocalizedString("Vietnam", comment: "Country name")

            // W
            case .WF: return NSLocalizedString("Wallis and Futuna", comment: "Country name")
            case .EH: return NSLocalizedString("Western Sahara", comment: "Country name")

            // Y
            case .YE: return NSLocalizedString("Yemen", comment: "Country name")

            // Z
            case .ZM: return NSLocalizedString("Zambia", comment: "Country name")
            case .ZW: return NSLocalizedString("Zimbabwe", comment: "Country name")
            }
        }
    }
}


// MARK: - Constants.
//
private extension SiteCountry {
    /// The key of the SiteSetting containing the store country
    enum Constants {
        static let countryKey = "woocommerce_default_country"
    }
}
