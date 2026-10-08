#!/usr/bin/env python3
"""Patch pinned Appium WebDriverAgent into a loopback-only location helper."""
from pathlib import Path
import sys

root = Path(sys.argv[1])
custom_path = root / "WebDriverAgentLib/Commands/FBCustomCommands.m"
custom = custom_path.read_text()


def replace_method(source, selector, next_selector, replacement):
    start = source.index(f"+ (id<FBResponsePayload>){selector}")
    end = source.index(f"+ (id<FBResponsePayload>){next_selector}", start)
    return source[:start] + replacement.strip() + "\n\n" + source[end:]


start = custom.index("+ (NSArray *)routes")
end = custom.index("#pragma mark - Commands", start)
custom = custom[:start] + '''+ (NSArray *)routes
{
  return @[
    [[FBRoute GET:@"/locus/capabilities"].withoutSession respondWithTarget:self action:@selector(handleLocusCapabilities:)],
    [[FBRoute GET:@"/wda/simulatedLocation"].withoutSession respondWithTarget:self action:@selector(handleGetSimulatedLocation:)],
    [[FBRoute POST:@"/wda/simulatedLocation"].withoutSession respondWithTarget:self action:@selector(handleSetSimulatedLocation:)],
    [[FBRoute DELETE:@"/wda/simulatedLocation"].withoutSession respondWithTarget:self action:@selector(handleClearSimulatedLocation:)],
  ];
}

+ (id<FBResponsePayload>)handleLocusCapabilities:(FBRouteRequest *)request
{
  return FBResponseWithObject(@{
    @"locusProtocolVersion": @1,
    @"speed": @YES,
    @"course": @YES,
    @"motion": @NO,
  });
}

''' + custom[end:]
custom = custom.replace('#import <CoreLocation/CoreLocation.h>', '#import <CoreLocation/CoreLocation.h>\n#import <math.h>')
custom = replace_method(custom, "handleGetSimulatedLocation:(FBRouteRequest *)request",
                        "handleSetSimulatedLocation:(FBRouteRequest *)request", '''
+ (id<FBResponsePayload>)handleGetSimulatedLocation:(FBRouteRequest *)request
{
  NSError *error;
  CLLocation *location = [XCUIDevice.sharedDevice fb_getSimulatedLocation:&error];
  if (nil != error) {
    return FBResponseWithStatus([FBCommandStatus unknownErrorWithMessage:error.description traceback:nil]);
  }
  return FBResponseWithObject(@{
    @"latitude": location ? @(location.coordinate.latitude) : NSNull.null,
    @"longitude": location ? @(location.coordinate.longitude) : NSNull.null,
    @"speed": location ? @(location.speed) : NSNull.null,
    @"course": location ? @(location.course) : NSNull.null,
    @"speedAccuracy": location ? @(location.speedAccuracy) : NSNull.null,
  });
}
''')
custom = replace_method(custom, "handleSetSimulatedLocation:(FBRouteRequest *)request",
                        "handleClearSimulatedLocation:(FBRouteRequest *)request", '''
+ (id<FBResponsePayload>)handleSetSimulatedLocation:(FBRouteRequest *)request
{
  NSNumber *latitude = request.arguments[@"latitude"];
  NSNumber *longitude = request.arguments[@"longitude"];
  NSNumber *speed = request.arguments[@"speed"];
  NSNumber *course = request.arguments[@"course"];
  if (![latitude isKindOfClass:NSNumber.class] || ![longitude isKindOfClass:NSNumber.class]
      || ![speed isKindOfClass:NSNumber.class] || ![course isKindOfClass:NSNumber.class]) {
    return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:@"Numeric latitude, longitude, speed (m/s), and course are required" traceback:nil]);
  }
  double lat = latitude.doubleValue;
  double lon = longitude.doubleValue;
  double velocity = speed.doubleValue;
  double heading = course.doubleValue;
  if (!isfinite(lat) || lat < -90. || lat > 90.
      || !isfinite(lon) || lon < -180. || lon > 180.
      || !isfinite(velocity) || velocity < 0. || velocity > 100.
      || !isfinite(heading) || (heading != -1. && (heading < 0. || heading >= 360.))) {
    return FBResponseWithStatus([FBCommandStatus invalidArgumentErrorWithMessage:@"Location fields are out of range" traceback:nil]);
  }
  CLLocation *location = [[CLLocation alloc]
      initWithCoordinate:CLLocationCoordinate2DMake(lat, lon)
      altitude:0.
      horizontalAccuracy:5.
      verticalAccuracy:-1.
      course:heading
      courseAccuracy:(heading < 0. ? -1. : 5.)
      speed:velocity
      speedAccuracy:0.5
      timestamp:[NSDate date]];
  NSError *error;
  if (![XCUIDevice.sharedDevice fb_setSimulatedLocation:location error:&error]) {
    return FBResponseWithStatus([FBCommandStatus unknownErrorWithMessage:error.description traceback:nil]);
  }
  return FBResponseWithOK();
}
''')
custom_path.write_text(custom)

server_path = root / "WebDriverAgentLib/Routing/FBWebServer.m"
server = server_path.read_text()
replacements = {
    'NSArray *handlersClasses = FBClassesThatConformsToProtocol(@protocol(FBCommandHandler));':
        'NSArray *handlersClasses = @[NSClassFromString(@"FBCustomCommands")];',
    '  [self initScreenshotsBroadcaster];\n': '',
    'NSRange serverPortRange = FBConfiguration.sharedInstance.bindingPortRange;':
        'NSRange serverPortRange = NSMakeRange(8100, 1);',
    'NSString *bindingIP = FBConfiguration.sharedInstance.bindingIPAddress;':
        'NSString *bindingIP = @"127.0.0.1";',
    '  [self.server setDefaultHeader:@"Access-Control-Allow-Origin" value:@"*"];\n': '',
    '  [self.server setDefaultHeader:@"Access-Control-Allow-Headers" value:@"Content-Type, X-Requested-With"];\n': '',
}
for original, replacement in replacements.items():
    if original not in server:
        raise RuntimeError(f"Pinned WebDriverAgent no longer matches: {original}")
    server = server.replace(original, replacement, 1)
server_path.write_text(server)
print("Patched native speed, course, strict field validation, location-only routes, and loopback binding.")
