//-------------------------------------------------------------------------------------------------------
// Copyright (C) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------
#import "Handle.h"

@implementation AceHandle

+ (NSMutableArray*) _objectsAssignedOnManagedSide {
    static NSMutableArray* oaoms = nil;
    if (oaoms == nil) {
        oaoms = [[NSMutableArray alloc] init];
    }
    return oaoms;
}

+ (NSMutableArray*) _objectsAssignedOnNativeSide {
    static NSMutableArray* oaons = nil;
    if (oaons == nil) {
        oaons = [[NSMutableArray alloc] init];
    }
    return oaons;
}

+ (NSMutableDictionary*) _managedHandleLookup {
    static NSMutableDictionary* map = nil;

    if (map == nil) {
        map = [[NSMutableDictionary alloc] init];
    }

    return map;
}

+ (NSMutableDictionary*) _nativeHandleLookup {
    static NSMutableDictionary* map = nil;

    if (map == nil) {
        map = [[NSMutableDictionary alloc] init];
    }

    return map;
}

// Create a handle from the native side
- (id) init {
    self = [super init];
    self->_value = [AceHandle _objectsAssignedOnNativeSide].count;
    self->_fromNative = true;
    return self;
}

+ (AceHandle*) createFromValue:(int) value fromNative:(BOOL) fromNative {
    AceHandle* h = [[AceHandle alloc] init];
    h->_value = value;
    h->_fromNative = fromNative;
    return h;
}

+ (AceHandle*) fromObject:(NSObject*)obj {
    if ([obj isKindOfClass:[UIView class]]) {
        return [((UIView*)obj).layer valueForKey:@"Ace.Handle"];
    }
    else {
        auto key = [NSNumber numberWithLongLong:(long long)obj];

        auto value = (NSNumber*)[[AceHandle _managedHandleLookup] objectForKey:key];

        if (value != nil) {
            return [AceHandle createFromValue:[value intValue] fromNative:false];
        }

        value = (NSNumber*)[[AceHandle _nativeHandleLookup] objectForKey:key];

        if (value != nil) {
            return [AceHandle createFromValue:[value intValue] fromNative:true];
        }

        return nil;
    }
}

+ (AceHandle*) fromJSON:(NSDictionary*) obj {
    int value = [(NSNumber*)obj[@"value"] intValue];
    NSNumber* fromNative = [obj objectForKey:@"fromNative"];
    if (fromNative == nil) {
        return [AceHandle createFromValue:value fromNative:false];
    }
    else {
        return [AceHandle createFromValue:value fromNative:[fromNative boolValue]];
    }
}

- (NSObject*) toObject {
    if (self->_fromNative) {
        return [[AceHandle _objectsAssignedOnNativeSide] objectAtIndex:self->_value];
    }
    else {
        return [[AceHandle _objectsAssignedOnManagedSide] objectAtIndex:self->_value];
    }
}

- (NSDictionary*) toJSON {
    NSMutableDictionary* d = [[NSMutableDictionary alloc] init];
    [d setObject:@"H" forKey:@"_t"];
    [d setObject:[NSNumber numberWithInt:self->_value] forKey:@"value"];
    if (self->_fromNative) {
        [d setObject:[NSNumber numberWithBool:true] forKey:@"fromNative"];
    }
    return d;
}

+ (NSObject*) deserialize:(NSDictionary*)obj {
    AceHandle* handle = [AceHandle fromJSON:obj];
    return [handle toObject];
}

- (void) register:(NSObject*)instance {
    if (self->_fromNative) {
        [self assign:instance list:[AceHandle _objectsAssignedOnNativeSide]];
        if ([instance isKindOfClass:[UIView class]]) {
            [((UIView*)instance).layer setValue:self forKey:@"Ace.Handle"];
        }
        else {
            auto key = [NSNumber numberWithLongLong:(long long)instance];
            auto value = [NSNumber numberWithInt:self->_value];
            [[AceHandle _nativeHandleLookup] setObject:value forKey:key];
        }
    }
    else {
        [self assign:instance list:[AceHandle _objectsAssignedOnManagedSide]];
        if ([instance isKindOfClass:[UIView class]]) {
            [((UIView*)instance).layer setValue:self forKey:@"Ace.Handle"];
        }
        else {
            auto key = [NSNumber numberWithLongLong:(long long)instance];
            auto value = [NSNumber numberWithInt:self->_value];
            [[AceHandle _managedHandleLookup] setObject:value forKey:key];
        }
    }
}

- (void) assign:(NSObject*)instance list:(NSMutableArray*)list {
    if ([list count] == self->_value) {
        [list addObject:instance];
    }
    else if ([list count] > self->_value) {
        list[self->_value] = instance;
    }
    else {
        // Just fill with nulls up to this point.
        // This would have been caused by an earlier instantiation exception,
        // but cascading errors simply from unexpected handles are annoying.
        while ([list count] < self->_value) {
            [list addObject:nil];
        }
        [list addObject:instance];
    }
}

@end
