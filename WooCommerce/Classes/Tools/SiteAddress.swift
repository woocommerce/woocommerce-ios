import Foundation
import Yosemite


/// Represent and parse the Address of the store, returned in the SiteSettings API `/settings/general/`
///
final class SiteAddress {

    private let siteSettings: [SiteSetting]

    var address: String {
        return getValueFromSiteSettings(Constants.address) ?? ""
    }

    var address2: String {
        return getValueFromSiteSettings(Constants.address2) ?? ""
    }

    var city: String {
        return getValueFromSiteSettings(Constants.city) ?? ""
    }

    var postalCode: String {
        return getValueFromSiteSettings(Constants.postalCode) ?? ""
    }

    var countryCode: String {
        return getValueFromSiteSettings(Constants.countryAndState)?.components(separatedBy: ":").first ?? ""
    }

    /// Returns the name of the country associated with the current store.
    /// The default store country is provided in a format like `HK:KOWLOON`
    /// This method will transform `HK:KOWLOON` into `Hong Kong`
    /// Will return nil if it can not figure out a valid country name
    var countryName: String? {
        guard
            let code = getValueFromSiteSettings(Constants.countryAndState)?.components(separatedBy: ":").first,
            let countryCode = CountryCode(rawValue: code) else {
                return nil
        }

        return countryCode.readableCountry
    }

    var state: String {
        return getValueFromSiteSettings(Constants.countryAndState)?.components(separatedBy: ":").last ?? ""
    }

    init(siteSettings: [SiteSetting] = ServiceLocator.selectedSiteSettings.siteSettings) {
        self.siteSettings = siteSettings
    }

    private func getValueFromSiteSettings(_ settingID: String) -> String? {
        return siteSettings.first { (setting) -> Bool in
            return setting.settingID == settingID
        }?.value
    }
}

// MARK: - Constants.
//
private extension SiteAddress {
    /// The key of the SiteSetting containing the store address
    enum Constants {
        static let address = "woocommerce_store_address"
        static let address2 = "woocommerce_store_address_2"
        static let city = "woocommerce_store_city"
        static let postalCode = "woocommerce_store_postcode"
        static let countryAndState = "woocommerce_default_country"
    }
}

// MARK: - Mapping between country codes and readable names
// The country names were extracted from the response to `/wp-json/wc/v3/settings/general`
// The default countries are listed under `woocommerce_default_country`
// in one of the following formats:
// - `"COUNTRY_CODE": "READABALE_COUNTRY_NAME"
// - `"COUNTRY_CODE:COUNTRY_REGION": "READABLE_COUNTRY_NAME - READABLE_COUNTRY_REGION"
extension SiteAddress {
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
        case UM
        case VI
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
            case .AX: return NSLocalizedString("Åland Islands", comment: "Country option for a site address.")
            case .AF: return NSLocalizedString("Afghanistan", comment: "Country option for a site address.")
            case .AL: return NSLocalizedString("Albania", comment: "Country option for a site address.")
            case .DZ: return NSLocalizedString("Algeria", comment: "Country option for a site address.")
            case .AS: return NSLocalizedString("American Samoa", comment: "Country option for a site address.")
            case .AD: return NSLocalizedString("Andorra", comment: "Country option for a site address.")
            case .AO: return NSLocalizedString("Angola", comment: "Country option for a site address.")
            case .AI: return NSLocalizedString("Anguilla", comment: "Country option for a site address.")
            case .AQ: return NSLocalizedString("Antarctica", comment: "Country option for a site address.")
            case .AG: return NSLocalizedString("Antigua and Barbuda", comment: "Country option for a site address.")
            case .AR: return NSLocalizedString("Argentina", comment: "Country option for a site address.")
            case .AM: return NSLocalizedString("Armenia", comment: "Country option for a site address.")
            case .AW: return NSLocalizedString("Aruba", comment: "Country option for a site address.")
            case .AU: return NSLocalizedString("Australia", comment: "Country option for a site address.")
            case .AT: return NSLocalizedString("Austria", comment: "Country option for a site address.")
            case .AZ: return NSLocalizedString("Azerbaijan", comment: "Country option for a site address.")

            // B
            case .BS: return NSLocalizedString("Bahamas", comment: "Country option for a site address.")
            case .BH: return NSLocalizedString("Bahrain", comment: "Country option for a site address.")
            case .BD: return NSLocalizedString("Bangladesh", comment: "Country option for a site address.")
            case .BB: return NSLocalizedString("Barbados", comment: "Country option for a site address.")
            case .BY: return NSLocalizedString("Belarus", comment: "Country option for a site address.")
            case .PW: return NSLocalizedString("Belau", comment: "Country option for a site address.")
            case .BE: return NSLocalizedString("Belgium", comment: "Country option for a site address.")
            case .BZ: return NSLocalizedString("Belize", comment: "Country option for a site address.")
            case .BJ: return NSLocalizedString("Benin", comment: "Country option for a site address.")
            case .BM: return NSLocalizedString("Bermuda", comment: "Country option for a site address.")
            case .BT: return NSLocalizedString("Bhutan", comment: "Country option for a site address.")
            case .BO: return NSLocalizedString("Bolivia", comment: "Country option for a site address.")
            case .BQ: return NSLocalizedString("Bonaire, Saint Eustatius and Saba", comment: "Country option for a site address.")
            case .BA: return NSLocalizedString("Bosnia and Herzegovina", comment: "Country option for a site address.")
            case .BW: return NSLocalizedString("Botswana", comment: "Country option for a site address.")
            case .BV: return NSLocalizedString("Bouvet Island", comment: "Country option for a site address.")
            case .BR: return NSLocalizedString("Brazil", comment: "Country option for a site address.")
            case .IO: return NSLocalizedString("British Indian Ocean Territory", comment: "Country option for a site address.")
            case .VG: return NSLocalizedString("British Virgin Islands", comment: "Country option for a site address.")
            case .BN: return NSLocalizedString("Brunei", comment: "Country option for a site address.")
            case .BG: return NSLocalizedString("Bulgaria", comment: "Country option for a site address.")
            case .BF: return NSLocalizedString("Burkina Faso", comment: "Country option for a site address.")
            case .BI: return NSLocalizedString("Burundi", comment: "Country option for a site address.")

            // C
            case .KH: return NSLocalizedString("Cambodia", comment: "Country option for a site address.")
            case .CM: return NSLocalizedString("Cameroon", comment: "Country option for a site address.")
            case .CA: return NSLocalizedString("Canada", comment: "Country option for a site address.")
            case .CV: return NSLocalizedString("Cape Verde", comment: "Country option for a site address.")
            case .KY: return NSLocalizedString("Cayman Islands", comment: "Country option for a site address.")
            case .CF: return NSLocalizedString("Central African Republic", comment: "Country option for a site address.")
            case .TD: return NSLocalizedString("Chad", comment: "Country option for a site address.")
            case .CL: return NSLocalizedString("Chile", comment: "Country option for a site address.")
            case .CN: return NSLocalizedString("China", comment: "Country option for a site address.")
            case .CX: return NSLocalizedString("Christmas Island", comment: "Country option for a site address.")
            case .CC: return NSLocalizedString("Cocos (Keeling) Islands", comment: "Country option for a site address.")
            case .CO: return NSLocalizedString("Colombia", comment: "Country option for a site address.")
            case .KM: return NSLocalizedString("Comoros", comment: "Country option for a site address.")
            case .CG: return NSLocalizedString("Congo (Brazzaville)", comment: "Country option for a site address.")
            case .CD: return NSLocalizedString("Congo (Kinshasa)", comment: "Country option for a site address.")
            case .CK: return NSLocalizedString("Cook Islands", comment: "Country option for a site address.")
            case .CR: return NSLocalizedString("Costa Rica", comment: "Country option for a site address.")
            case .HR: return NSLocalizedString("Croatia", comment: "Country option for a site address.")
            case .CU: return NSLocalizedString("Cuba", comment: "Country option for a site address.")
            case .CW: return NSLocalizedString("Curacao", comment: "Country option for a site address.")
            case .CY: return NSLocalizedString("Cyprus", comment: "Country option for a site address.")
            case .CZ: return NSLocalizedString("Czech Republic", comment: "Country option for a site address.")

            // D
            case .DK: return NSLocalizedString("Denmark", comment: "Country option for a site address.")
            case .DJ: return NSLocalizedString("Djibouti", comment: "Country option for a site address.")
            case .DM: return NSLocalizedString("Dominica", comment: "Country option for a site address.")
            case .DO: return NSLocalizedString("Dominican Republic", comment: "Country option for a site address.")

            // E
            case .EC: return NSLocalizedString("Ecuador", comment: "Country option for a site address.")
            case .EG: return NSLocalizedString("Egypt", comment: "Country option for a site address.")
            case .SV: return NSLocalizedString("El Salvador", comment: "Country option for a site address.")
            case .GQ: return NSLocalizedString("Equatorial Guinea", comment: "Country option for a site address.")
            case .ER: return NSLocalizedString("Eritrea", comment: "Country option for a site address.")
            case .EE: return NSLocalizedString("Estonia", comment: "Country option for a site address.")
            case .ET: return NSLocalizedString("Ethiopia", comment: "Country option for a site address.")

            // F
            case .FK: return NSLocalizedString("Falkland Islands", comment: "Country option for a site address.")
            case .FO: return NSLocalizedString("Faroe Islands", comment: "Country option for a site address.")
            case .FJ: return NSLocalizedString("Fiji", comment: "Country option for a site address.")
            case .FI: return NSLocalizedString("Finland", comment: "Country option for a site address.")
            case .FR: return NSLocalizedString("France", comment: "Country option for a site address.")
            case .GF: return NSLocalizedString("French Guiana", comment: "Country option for a site address.")
            case .PF: return NSLocalizedString("French Polynesia", comment: "Country option for a site address.")
            case .TF: return NSLocalizedString("French Southern Territories", comment: "Country option for a site address.")

            // G
            case .GA: return NSLocalizedString("Gabon", comment: "Country option for a site address.")
            case .GM: return NSLocalizedString("Gambia", comment: "Country option for a site address.")
            case .GE: return NSLocalizedString("Georgia", comment: "Country option for a site address.")
            case .DE: return NSLocalizedString("Germany", comment: "Country option for a site address.")
            case .GH: return NSLocalizedString("Ghana", comment: "Country option for a site address.")
            case .GI: return NSLocalizedString("Gibraltar", comment: "Country option for a site address.")
            case .GR: return NSLocalizedString("Greece", comment: "Country option for a site address.")
            case .GL: return NSLocalizedString("Greenland", comment: "Country option for a site address.")
            case .GD: return NSLocalizedString("Grenada", comment: "Country option for a site address.")
            case .GP: return NSLocalizedString("Guadeloupe", comment: "Country option for a site address.")
            case .GU: return NSLocalizedString("Guam", comment: "Country option for a site address.")
            case .GT: return NSLocalizedString("Guatemala", comment: "Country option for a site address.")
            case .GG: return NSLocalizedString("Guernsey", comment: "Country option for a site address.")
            case .GN: return NSLocalizedString("Guinea", comment: "Country option for a site address.")
            case .GW: return NSLocalizedString("Guinea-Bissau", comment: "Country option for a site address.")
            case .GY: return NSLocalizedString("Guyana", comment: "Country option for a site address.")

            // H
            case .HT: return NSLocalizedString("Haiti", comment: "Country option for a site address.")
            case .HM: return NSLocalizedString("Heard Island and McDonald Islands", comment: "Country option for a site address.")
            case .HN: return NSLocalizedString("Honduras", comment: "Country option for a site address.")
            case .HK: return NSLocalizedString("Hong Kong", comment: "Country option for a site address.")
            case .HU: return NSLocalizedString("Hungary", comment: "Country option for a site address.")

            // I
            case .IS: return NSLocalizedString("Iceland", comment: "Country option for a site address.")
            case .IN: return NSLocalizedString("India", comment: "Country option for a site address.")
            case .ID: return NSLocalizedString("Indonesia", comment: "Country option for a site address.")
            case .IR: return NSLocalizedString("Iran", comment: "Country option for a site address.")
            case .IQ: return NSLocalizedString("Iraq", comment: "Country option for a site address.")
            case .IE: return NSLocalizedString("Ireland", comment: "Country option for a site address.")
            case .IM: return NSLocalizedString("Isle of Man", comment: "Country option for a site address.")
            case .IL: return NSLocalizedString("Israel", comment: "Country option for a site address.")
            case .IT: return NSLocalizedString("Italy", comment: "Country option for a site address.")
            case .CI: return NSLocalizedString("Ivory Coast", comment: "Country option for a site address.")

            // J
            case .JM: return NSLocalizedString("Jamaica", comment: "Country option for a site address.")
            case .JP: return NSLocalizedString("Japan", comment: "Country option for a site address.")
            case .JE: return NSLocalizedString("Jersey", comment: "Country option for a site address.")
            case .JO: return NSLocalizedString("Jordan", comment: "Country option for a site address.")

            // K
            case .KZ: return NSLocalizedString("Kazakhstan", comment: "Country option for a site address.")
            case .KE: return NSLocalizedString("Kenya", comment: "Country option for a site address.")
            case .KI: return NSLocalizedString("Kiribati", comment: "Country option for a site address.")
            case .KW: return NSLocalizedString("Kuwait", comment: "Country option for a site address.")
            case .KG: return NSLocalizedString("Kyrgyzstan", comment: "Country option for a site address.")

            // L
            case .LA: return NSLocalizedString("Laos", comment: "Country option for a site address.")
            case .LV: return NSLocalizedString("Latvia", comment: "Country option for a site address.")
            case .LB: return NSLocalizedString("Lebanon", comment: "Country option for a site address.")
            case .LS: return NSLocalizedString("Lesotho", comment: "Country option for a site address.")
            case .LR: return NSLocalizedString("Liberia", comment: "Country option for a site address.")
            case .LY: return NSLocalizedString("Libya", comment: "Country option for a site address.")
            case .LI: return NSLocalizedString("Liechtenstein", comment: "Country option for a site address.")
            case .LT: return NSLocalizedString("Lithuania", comment: "Country option for a site address.")
            case .LU: return NSLocalizedString("Luxembourg", comment: "Country option for a site address.")

            // M
            case .MO: return NSLocalizedString("Macao S.A.R., China", comment: "Country option for a site address.")
            case .MK: return NSLocalizedString("Macedonia", comment: "Country option for a site address.")
            case .MG: return NSLocalizedString("Madagascar", comment: "Country option for a site address.")
            case .MW: return NSLocalizedString("Malawi", comment: "Country option for a site address.")
            case .MY: return NSLocalizedString("Malaysia", comment: "Country option for a site address.")
            case .MV: return NSLocalizedString("Maldives", comment: "Country option for a site address.")
            case .ML: return NSLocalizedString("Mali", comment: "Country option for a site address.")
            case .MT: return NSLocalizedString("Malta", comment: "Country option for a site address.")
            case .MH: return NSLocalizedString("Marshall Islands", comment: "Country option for a site address.")
            case .MQ: return NSLocalizedString("Martinique", comment: "Country option for a site address.")
            case .MR: return NSLocalizedString("Mauritania", comment: "Country option for a site address.")
            case .MU: return NSLocalizedString("Mauritius", comment: "Country option for a site address.")
            case .YT: return NSLocalizedString("Mayotte", comment: "Country option for a site address.")
            case .MX: return NSLocalizedString("Mexico", comment: "Country option for a site address.")
            case .FM: return NSLocalizedString("Micronesia", comment: "Country option for a site address.")
            case .MD: return NSLocalizedString("Moldova", comment: "Country option for a site address.")
            case .MC: return NSLocalizedString("Monaco", comment: "Country option for a site address.")
            case .MN: return NSLocalizedString("Mongolia", comment: "Country option for a site address.")
            case .ME: return NSLocalizedString("Montenegro", comment: "Country option for a site address.")
            case .MS: return NSLocalizedString("Montserrat", comment: "Country option for a site address.")
            case .MA: return NSLocalizedString("Morocco", comment: "Country option for a site address.")
            case .MZ: return NSLocalizedString("Mozambique", comment: "Country option for a site address.")
            case .MM: return NSLocalizedString("Myanmar", comment: "Country option for a site address.")

            // N
            case .NA: return NSLocalizedString("Namibia", comment: "Country option for a site address.")
            case .NR: return NSLocalizedString("Nauru", comment: "Country option for a site address.")
            case .NP: return NSLocalizedString("Nepal", comment: "Country option for a site address.")
            case .NL: return NSLocalizedString("Netherlands", comment: "Country option for a site address.")
            case .NC: return NSLocalizedString("New Caledonia", comment: "Country option for a site address.")
            case .NZ: return NSLocalizedString("New Zealand", comment: "Country option for a site address.")
            case .NI: return NSLocalizedString("Nicaragua", comment: "Country option for a site address.")
            case .NE: return NSLocalizedString("Niger", comment: "Country option for a site address.")
            case .NG: return NSLocalizedString("Nigeria", comment: "Country option for a site address.")
            case .NU: return NSLocalizedString("Niue", comment: "Country option for a site address.")
            case .NF: return NSLocalizedString("Norfolk Island", comment: "Country option for a site address.")
            case .KP: return NSLocalizedString("North Korea", comment: "Country option for a site address.")
            case .MP: return NSLocalizedString("Northern Mariana Islands", comment: "Country option for a site address.")
            case .NO: return NSLocalizedString("Norway", comment: "Country option for a site address.")

            // O
            case .OM: return NSLocalizedString("Oman", comment: "Country option for a site address.")

            // P
            case .PK: return NSLocalizedString("Pakistan", comment: "Country option for a site address.")
            case .PS: return NSLocalizedString("Palestinian Territory", comment: "Country option for a site address.")
            case .PA: return NSLocalizedString("Panama", comment: "Country option for a site address.")
            case .PG: return NSLocalizedString("Papua New Guinea", comment: "Country option for a site address.")
            case .PY: return NSLocalizedString("Paraguay", comment: "Country option for a site address.")
            case .PE: return NSLocalizedString("Peru", comment: "Country option for a site address.")
            case .PH: return NSLocalizedString("Philippines", comment: "Country option for a site address.")
            case .PN: return NSLocalizedString("Pitcairn", comment: "Country option for a site address.")
            case .PL: return NSLocalizedString("Poland", comment: "Country option for a site address.")
            case .PT: return NSLocalizedString("Portugal", comment: "Country option for a site address.")
            case .PR: return NSLocalizedString("Puerto Rico", comment: "Country option for a site address.")

            // Q
            case .QA: return NSLocalizedString("Qatar", comment: "Country option for a site address.")

            // R
            case .RE: return NSLocalizedString("Reunion", comment: "Country option for a site address.")
            case .RO: return NSLocalizedString("Romania", comment: "Country option for a site address.")
            case .RU: return NSLocalizedString("Russia", comment: "Country option for a site address.")
            case .RW: return NSLocalizedString("Rwanda", comment: "Country option for a site address.")

            // S
            case .ST: return NSLocalizedString("São Tomé and Príncipe", comment: "Country option for a site address.")
            case .BL: return NSLocalizedString("Saint Barthélemy", comment: "Country option for a site address.")
            case .SH: return NSLocalizedString("Saint Helena", comment: "Country option for a site address.")
            case .KN: return NSLocalizedString("Saint Kitts and Nevis", comment: "Country option for a site address.")
            case .LC: return NSLocalizedString("Saint Lucia", comment: "Country option for a site address.")
            case .SX: return NSLocalizedString("Saint Martin (Dutch part)", comment: "Country option for a site address.")
            case .MF: return NSLocalizedString("Saint Martin (French part)", comment: "Country option for a site address.")
            case .PM: return NSLocalizedString("Saint Pierre and Miquelon", comment: "Country option for a site address.")
            case .VC: return NSLocalizedString("Saint Vincent and the Grenadines", comment: "Country option for a site address.")
            case .WS: return NSLocalizedString("Samoa", comment: "Country option for a site address.")
            case .SM: return NSLocalizedString("San Marino", comment: "Country option for a site address.")
            case .SA: return NSLocalizedString("Saudi Arabia", comment: "Country option for a site address.")
            case .SN: return NSLocalizedString("Senegal", comment: "Country option for a site address.")
            case .RS: return NSLocalizedString("Serbia", comment: "Country option for a site address.")
            case .SC: return NSLocalizedString("Seychelles", comment: "Country option for a site address.")
            case .SL: return NSLocalizedString("Sierra Leone", comment: "Country option for a site address.")
            case .SG: return NSLocalizedString("Singapore", comment: "Country option for a site address.")
            case .SK: return NSLocalizedString("Slovakia", comment: "Country option for a site address.")
            case .SI: return NSLocalizedString("Slovenia", comment: "Country option for a site address.")
            case .SB: return NSLocalizedString("Solomon Islands", comment: "Country option for a site address.")
            case .SO: return NSLocalizedString("Somalia", comment: "Country option for a site address.")
            case .ZA: return NSLocalizedString("South Africa", comment: "Country option for a site address.")
            case .GS: return NSLocalizedString("South Georgia/Sandwich Islands", comment: "Country option for a site address.")
            case .KR: return NSLocalizedString("South Korea", comment: "Country option for a site address.")
            case .SS: return NSLocalizedString("South Sudan", comment: "Country option for a site address.")
            case .ES: return NSLocalizedString("Spain", comment: "Country option for a site address.")
            case .LK: return NSLocalizedString("Sri Lanka", comment: "Country option for a site address.")
            case .SD: return NSLocalizedString("Sudan", comment: "Country option for a site address.")
            case .SR: return NSLocalizedString("Suriname", comment: "Country option for a site address.")
            case .SJ: return NSLocalizedString("Svalbard and Jan Mayen", comment: "Country option for a site address.")
            case .SZ: return NSLocalizedString("Swaziland", comment: "Country option for a site address.")
            case .SE: return NSLocalizedString("Sweden", comment: "Country option for a site address.")
            case .CH: return NSLocalizedString("Switzerland", comment: "Country option for a site address.")
            case .SY: return NSLocalizedString("Syria", comment: "Country option for a site address.")

            // T
            case .TW: return NSLocalizedString("Taiwan", comment: "Country option for a site address.")
            case .TJ: return NSLocalizedString("Tajikistan", comment: "Country option for a site address.")
            case .TZ: return NSLocalizedString("Tanzania", comment: "Country option for a site address.")
            case .TH: return NSLocalizedString("Thailand", comment: "Country option for a site address.")
            case .TL: return NSLocalizedString("Timor-Leste", comment: "Country option for a site address.")
            case .TG: return NSLocalizedString("Togo", comment: "Country option for a site address.")
            case .TK: return NSLocalizedString("Tokelau", comment: "Country option for a site address.")
            case .TO: return NSLocalizedString("Tonga", comment: "Country option for a site address.")
            case .TT: return NSLocalizedString("Trinidad and Tobago", comment: "Country option for a site address.")
            case .TN: return NSLocalizedString("Tunisia", comment: "Country option for a site address.")
            case .TR: return NSLocalizedString("Turkey", comment: "Country option for a site address.")
            case .TM: return NSLocalizedString("Turkmenistan", comment: "Country option for a site address.")
            case .TC: return NSLocalizedString("Turks and Caicos Islands", comment: "Country option for a site address.")
            case .TV: return NSLocalizedString("Tuvalu", comment: "Country option for a site address.")

            // U
            case .UG: return NSLocalizedString("Uganda", comment: "Country option for a site address.")
            case .UA: return NSLocalizedString("Ukraine", comment: "Country option for a site address.")
            case .AE: return NSLocalizedString("United Arab Emirates", comment: "Country option for a site address.")
            case .GB: return NSLocalizedString("United Kingdom", comment: "Country option for a site address.")
            case .US: return NSLocalizedString("United States", comment: "Country option for a site address.")
            case .UM: return NSLocalizedString("United States Minor Outlying Islands", comment: "Country option for a site address.")
            case .VI: return NSLocalizedString("United States Virgin Islands", comment: "Country option for a site address.")
            case .UY: return NSLocalizedString("Uruguay", comment: "Country option for a site address.")
            case .UZ: return NSLocalizedString("Uzbekistan", comment: "Country option for a site address.")

            // V
            case .VU: return NSLocalizedString("Vanuatu", comment: "Country option for a site address.")
            case .VA: return NSLocalizedString("Vatican", comment: "Country option for a site address.")
            case .VE: return NSLocalizedString("Venezuela", comment: "Country option for a site address.")
            case .VN: return NSLocalizedString("Vietnam", comment: "Country option for a site address.")

            // W
            case .WF: return NSLocalizedString("Wallis and Futuna", comment: "Country option for a site address.")
            case .EH: return NSLocalizedString("Western Sahara", comment: "Country option for a site address.")

            // Y
            case .YE: return NSLocalizedString("Yemen", comment: "Country option for a site address.")

            // Z
            case .ZM: return NSLocalizedString("Zambia", comment: "Country option for a site address.")
            case .ZW: return NSLocalizedString("Zimbabwe", comment: "Country option for a site address.")
            }
        }
    }
}
