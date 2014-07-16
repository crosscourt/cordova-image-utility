/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "imageUtility.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation ImageUtility 

- (void) getExifData:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = nil;
    NSString *fileArg = [command.arguments objectAtIndex:0];
    NSLog(@"%@", fileArg);
    NSURL * url = [NSURL URLWithString: fileArg];
   
    if (url) { // && url.scheme && url.host) {
        
        // the locks for blocking
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);

        __block NSDictionary *metadata = nil;
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        dispatch_async(queue, ^{
            [library assetForURL:url
                 resultBlock:^(ALAsset *asset)  {
                     metadata = asset.defaultRepresentation.metadata;
                     dispatch_semaphore_signal(sema);
                     /*
                     if (metadata) {
                         NSNumber *longitude = metadata[@"{GPS}"][@"Longitude"];
                         NSNumber *latitude = metadata[@"{GPS}"][@"Latitude"];
                         if (longitude && latitude) {
                             NSLog(@"%@", longitude);
                             NSLog(@"%@", latitude);
                         }
                     }
                     */
                 }
                failureBlock:^(NSError *error) {
                    NSLog(@"Unable to access image: %@", error);
                    dispatch_semaphore_signal(sema);
                }];
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        //dispatch_release(sema);
        
        if (metadata) {
            // just in case
            NSError * serialerror = nil;
            
            // attempt to serialize the meta data dict
            NSData * dat = [NSJSONSerialization dataWithJSONObject: metadata options: 0 error: &serialerror];
            
            if (serialerror == nil) {
                NSString * jsonstr = [[NSString alloc]initWithData:dat encoding:NSUTF8StringEncoding];
                pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: jsonstr];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Arg was null"];
            }
        } else {
            NSString * invalidurlerror = [[NSString alloc] initWithFormat:@"ExifReader Could not find resource %@", fileArg];
            pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR
                                             messageAsString: invalidurlerror];
        }
    } else {
        NSString * invalidurlerror = [[NSString alloc] initWithFormat:@"ExifReader Says %@ is an invalid URL!", fileArg];
        pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR
                                         messageAsString: invalidurlerror];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
