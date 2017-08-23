/******************************************************************************
 Copyright (c) 2012, Google Inc.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 * Neither the name of Google Inc. nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 Created by Mark Cogan on 4/29/2011.

 ******************************************************************************/

#import "HAR.h"
#import <UIKit/UIKit.h>
#import "NSDate+ISO8601.h"

@implementation HAR

// returns a new HAR dictionary populated with Creator and Browser entries
// and including an empty mutable Entries array
+ (NSDictionary *)HAR {
  NSMutableDictionary *HARLog =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
      @"1.2" , kHARVersion,
      nil];

  // retrieve the app name and version from the main bundle and
  // put them in the HAR Creator record.
  NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
  NSDictionary *HARCreator = [NSDictionary dictionaryWithObjectsAndKeys:
          [infoDictionary objectForKey:@"CFBundleDisplayName"], kHARName,
              [infoDictionary objectForKey:@"CFBundleVersion"], kHARVersion,
                              nil];

  // use "UIWebView" and the current OS version for the HAR Browser record
  // TODO(marq) support optional browser name
  NSDictionary *HARBrowser = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"UIWebView", kHARName,
    [[UIDevice currentDevice] systemVersion], kHARVersion,
                              nil];

  [HARLog setObject:HARCreator forKey:kHARCreator];
  [HARLog setObject:HARBrowser forKey:kHARBrowser];

  // create an empty (but mutable) array for HAR entries.
  [HARLog setObject:[NSMutableArray array] forKey:kHAREntries];

  // At this point the dictionary is a valid HAR log when transformed to JSON.
  return HARLog;
}

// Creates a HAR page dictionary with an id of |pageId| and a title of |title|,
// and a boilerplate pageTimings value with -1s for both OnLoad and
// OnContentLoad
+ (NSDictionary *)HARPageWithId:(NSString *)pageId
                          title:(NSString *)title
                 pageProperties:(NSDictionary*)pageProperties {
  NSMutableDictionary *pageTimings =
      [NSMutableDictionary dictionaryWithObjectsAndKeys:
          @(kHARUnknownTimeInterval), kHAROnContentLoad,
          @(kHARUnknownTimeInterval), kHAROnLoad,
          // TODO(skerner): Support onRender
                                    nil];

  NSMutableDictionary *result =
      [NSMutableDictionary dictionaryWithObjectsAndKeys:
          [[NSDate date] ISO8601Representation], kHARStarted,
                                         pageId, kHARId,
                                          title, kHARTitle,
                                    pageTimings, kHARPageTimings,
                                            nil];

  if (pageProperties != nil) {
    NSEnumerator *propertyEnumerator = [pageProperties keyEnumerator];
    id key;
    while ((key = [propertyEnumerator nextObject])) {
      [result setObject:[pageProperties valueForKey:key]
                 forKey:key];
    }
  }

  return result;
}

// For debugging: walks through the entries in |HAR| and validates that they
// contain responses and send and wait timings. Exceptions are logged to the
// console.
+ (void)HARAudit:(NSDictionary *)HAR {
  NSArray *entries = (NSArray *)[HAR objectForKey:kHAREntries];

  NSUInteger entryCount = 0;
  for (NSDictionary *entry in entries) {
    NSDictionary *response = [entry objectForKey:kHARResponse];
    NSDictionary *request = [entry objectForKey:kHARRequest];

    // does the entry have a response?
    if (nil == response) {
      NSLog(@"Entry %tu for %@ missing response",entryCount,
            [request objectForKey:kHARURL]);
    }
    NSDictionary *timings = [entry objectForKey:kHARTimings];
    // does the entry have a timings record?
    if (nil == timings) {
      NSLog(@"Entry %tu for %@ missing timings",entryCount,
            [request objectForKey:kHARURL]);
    } else {
      // does the timings record have send and wait fields
      if (nil == [timings objectForKey:kHARSend]) {
        NSLog(@"Timings %tu for %@ missing send",entryCount,
              [request objectForKey:kHARURL]);
      }
      if (nil == [timings objectForKey:kHARWait]) {
        NSLog(@"Timings %tu for %@ missing wait",entryCount,
              [request objectForKey:kHARURL]);
      }
    }

    entryCount++;
  }
}

// Returns an array of HAR HTTP cookie structures corresponding to the
// contents of |cookies|. |cookies| is expected to be an array containing only
// NSHTTPCookie objects.
+ (NSMutableArray *)HARCookiesFromCookieArray:(NSArray *)cookies {
  NSMutableArray *HARCookies = [NSMutableArray arrayWithCapacity:[cookies count]];
  for (NSHTTPCookie *requestCookie in cookies) {
    NSString *expiresDate = [[requestCookie expiresDate] ISO8601Representation];
    // map the |requestCookie| properties to HAR cookie record values
    NSDictionary *HARCookie = [NSDictionary dictionaryWithObjectsAndKeys:
                               requestCookie.name,              kHARName,
                               requestCookie.value,             kHARValue,
                               requestCookie.path,              kHARPath,
                               requestCookie.domain,            kHARDomain,
                               expiresDate,                     kHARExpires,
                               @([requestCookie isHTTPOnly]),   kHARHTTPOnly,
                               nil];
    [HARCookies addObject:HARCookie];
  }

  return HARCookies;
}

// Given a dictionary of name-value pairs (|headers|) which correspond to
// HTTP request or response headers, update the HAR request or response structure
// |HAR| by adding a Headers array of HAR headers structures, and adding a
// headersSize value corresponding to the totaly bytes of header data implied
// by |headers|
//
// Note that if |DEBUG_TIMING| is true, the header array that's added to |HAR|
// is always empty
+ (void)addHARHeadersFromDictionary:(NSDictionary *)headers
                              toHAR:(NSMutableDictionary *)HAR {
  __block NSUInteger headerBytes = 0;
  NSMutableArray *HARHeaders = [NSMutableArray array];

  [headers enumerateKeysAndObjectsUsingBlock:
   ^(id headerName, id headerValue, BOOL *stop) {
     // Since the header has already been parsed for us, we assume that it was
     // formatted with a colon and space after the name (two bytes) and
     // a CRLF after the value (two more bytes)
     headerBytes += [(NSString *)headerName length]  + 2 +
                    [(NSString *)headerValue length] + 2;
     [HARHeaders addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                            headerName,  kHARName,
                            headerValue, kHARValue,
                            nil
                            ]
      ];
   }
   ];

  headerBytes += 2; // final CR LF

  if (DEBUG_TIMING) {
    [HAR setObject:[NSArray array] forKey:kHARHeaders];
  } else {
    [HAR setObject:HARHeaders forKey:kHARHeaders];
  }

  [HAR setObject:@(headerBytes) forKey:kHARHeadersSize];
}

+ (NSURL *)generateWithModelObjects:(NSArray<NEHTTPModel *> *)modelObjects {
    NSString *harVersion = @"1.2";

    // creator
    NSDictionary *creator = @{
                              kHARName: @"NetworkEye",
                              kHARVersion: @"2.0.0",
                              kHARComment: @"https://github.com/team-supercharge/NetworkEye",
                              };

    // browser
    NSString *appName = [[NSBundle mainBundle].infoDictionary objectForKey:(NSString *)kCFBundleNameKey];
    NSString *versionNumber = [NSString stringWithFormat:@"%@ (%@)",
                               [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                               [[NSBundle mainBundle].infoDictionary objectForKey:(NSString *)kCFBundleVersionKey]];
    NSString *appNameVersionCombined = [NSString stringWithFormat:@"%@ %@", appName, versionNumber];
    NSDictionary *browser = @{
                              kHARName: appName,
                              kHARVersion: versionNumber,
                              //kHARComment: @"",
                              };

    // pages
    NSArray *pages = @[
                       @{
                           kHARStarted: [modelObjects.lastObject.startDate ISO8601Representation],
                           kHARId: appNameVersionCombined,
                           kHARTitle: appNameVersionCombined,
                           kHARPageTimings: @{
                                   kHAROnContentLoad: @0.0,
                                   kHAROnLoad: @0.0,
                                   //kHARComment: @"",
                                   },
                           //kHARComment: @"",
                           }
                       ];

    NSMutableArray *entries = [NSMutableArray new];
    [modelObjects enumerateObjectsUsingBlock:^(NEHTTPModel *model, NSUInteger idx, BOOL *stop) {
        // entries
        NSDictionary *request = [model.ne_request HARRepresentation];
        NSDictionary *response = [model.ne_response HARRepresentationWithData:model.receiveData];

        NSTimeInterval seconds = [model.endDate timeIntervalSinceDate:model.startDate];
        NSTimeInterval wait = seconds * 1000.0;

        NSDictionary *timings = @{
                                  kHARBlocked: @(-1.0),
                                  kHARDNS: @(-1.0),
                                  kHARConnect: @(-1.0),
                                  kHARSend: @(-1.0),
                                  kHARWait: @(wait),
                                  kHARReceive: @(-1.0),
                                  kHARSSL: @(-1.0),
                                  //kHARComment: @"",
                                  };

        NSDictionary *anEntry = @{
                                  kHARPageRef: appNameVersionCombined,
                                  kHARStarted: [model.startDate ISO8601Representation],
                                  kHARTime: @(wait),
                                  kHARRequest: request,
                                  kHARResponse: response,
                                  kHARCache: @{},
                                  kHARTimings: timings,
                                  //kHARServerIPAddress: @"",
                                  //kHARConnection: @"",
                                  //kHARComment: @"",
                                  };
        [entries addObject:anEntry];
    }];

    // creating the full result
    NSDictionary *resultDictionary = @{
                                       kHARLog: @{
                                               kHARVersion: harVersion,
                                               kHARCreator: creator,
                                               kHARBrowser: browser,
                                               kHARPages: pages,
                                               kHAREntries: entries,
                                               //kHARComment: @"",
                                               }
                                       };

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultDictionary
                                                       options:0
                                                         error:&error];
    if (error) {
        return nil;
    }
    NSString *resultString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //NSLog(@"👉%@👈", resultString);

    NSString *fileName = [NSString stringWithFormat:@"%@ %@.har", appNameVersionCombined, [NSDate date]];
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
                          stringByAppendingPathComponent:fileName];
    BOOL success = [resultString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    NSURL *filePathURL = [NSURL fileURLWithPath:filePath];

    if (success && !error && filePathURL) {
        return filePathURL;
    }
    return nil;
}

@end
