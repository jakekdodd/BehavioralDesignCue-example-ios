//
//  ASIdHelper.m
//  BoundlessKit
//
//  Created by Akash Desai on 10/12/17.
//

#import "ASIdHelper.h"

@implementation ASIdHelper
+ (nullable NSUUID*) adId {
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        id asIdManager = [ASIdentifierManagerClass valueForKey:@"sharedManager"];
        if ([[asIdManager valueForKey:@"advertisingTrackingEnabled"] isEqual:[NSNumber numberWithInt:1]])
        return [asIdManager valueForKey:@"advertisingIdentifier"];
    }
    
    return NULL;
}
@end
