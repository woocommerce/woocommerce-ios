#import "WPAuthenticatorLogging.h"
#import "WPAuthenticatorLoggingPrivate.h"

DDLogLevel WPAuthenticatorGetLoggingLevel() {
    return ddLogLevel;
}

void WPAuthenticatorSetLoggingLevel(DDLogLevel level) {
    ddLogLevel = level;
}
