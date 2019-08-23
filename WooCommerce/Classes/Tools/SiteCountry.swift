import Foundation
import Yosemite

final class SiteCountry {
    /// ResultsController. Fetches the store country from SiteSetting
    ///
    private lazy var resultsController: ResultsController<StorageSiteSetting> = {
        let storageManager = ServiceLocator.storageManager
        let sitePredicate = NSPredicate(format: "siteID == %lld", ServiceLocator.stores.sessionManager.defaultStoreID ?? Int.min)
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
