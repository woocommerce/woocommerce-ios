import Foundation

// MARK: - Mapping between country codes and readable names
// The country names were extracted from the response to `/wp-json/wc/v3/settings/general`
// The default countries are listed under `woocommerce_default_country`
// in one of the following formats:
// - `"COUNTRY_CODE": "READABALE_COUNTRY_NAME"
// - `"COUNTRY_CODE:COUNTRY_REGION": "READABLE_COUNTRY_NAME - READABLE_COUNTRY_REGION"
public enum CountryCode: String, CaseIterable {
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

    case unknown
}
