// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "Country.h"
#import "Wire-Swift.h"

@import CoreTelephony;


NS_ASSUME_NONNULL_BEGIN
@implementation Country

+ (Country *)defaultCountry
{
    Country *defaultCountry = nil;

#if WIRESTAN
    NSString *backendEnvironment = [[NSUserDefaults standardUserDefaults] stringForKey:@"ZMBackendEnvironmentType"];
    if ([backendEnvironment isEqualToString:@"staging"]) {
        defaultCountry = [Country countryWirestan];
    }

#endif
    if (!defaultCountry) {
        defaultCountry = [Country countryFromDevice] ?: [Country countryWithISO:@"us" e164:@1];
    }

    return defaultCountry;
}

+ (nullable instancetype)countryWithISO:(NSString *)ISO e164:(NSNumber *)e164
{
    Country *country = [[Country alloc] init];
    country.ISO = ISO;
    country.e164 = e164;
    
    return country;
}

+ (nullable instancetype)detectCountryFromCode:(NSUInteger)e164;
{
    return [self detectCountryWithMatcher:^(Country *country) {
        return (BOOL)(country.e164.unsignedIntegerValue == e164);
    }];
}

+ (nullable instancetype)detectCountryForPhoneNumber:(NSString *)phoneNumber
{
    return [self detectCountryWithMatcher:^(Country *country) {
        return [phoneNumber hasPrefix:country.e164PrefixString];
    }];
}

+ (nullable instancetype)detectCountryWithMatcher:(BOOL (^ _Nonnull)(Country *))matcher
{
    NSMutableSet *matches = [NSMutableSet new];
    NSArray *allCountries = [self allCountries];
    for (Country *country in allCountries) {
        if (matcher(country)) {
            [matches addObject:country];
        }
    }

    // One or no matches is trivial case
    if (matches.count <= 1) {
        return matches.anyObject;
    }

    // If country from device is in match list, probably it is desired by user
    Country *countryFromDevice = [Country countryFromDevice];
    if (countryFromDevice != nil && [matches containsObject:countryFromDevice]) {
        return countryFromDevice;
    }

    // List to prioritize main countries with shared prefixes (e.g., USA with "+1")
    NSArray *priorityList = @[@"us", @"it", @"fi", @"tz", @"uk", @"no", @"ru"];

    for (Country *country in matches) {
        if([priorityList containsObject:country.ISO]) {
            return country;
        }
    }

    // Feel free to add more smart heuristics here:
    return matches.anyObject;
}

+ (NSArray *)allCountries
{
    NSDictionary *countryCodeDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CountryCodes" ofType:@"plist"]];
    NSMutableArray *countries = [NSMutableArray array];

    #if WIRESTAN
    [countries addObject:Country.countryWirestan];
    #endif
    
    for (NSDictionary *countryData in [countryCodeDict objectForKey:@"countryCodes"]) {
        [countries addObject:[Country countryWithISO:[countryData valueForKey:@"iso"] e164:[countryData valueForKey:@"e164"]]];
    }

    return [countries copy];
}

#if WIRESTAN
+ (instancetype)countryWirestan
{
    Country *wirestan = [Country new];
    wirestan.e164 = @(000);
    wirestan.ISO = @"WIS";
    return wirestan;
}
#endif

- (NSString *)displayName
{
#if WIRESTAN 
    if ([self.ISO isEqualToString:@"WIS"]) {
        return @"Wirestan ☀️";
    }
#endif
    NSString *localized = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:self.ISO];
    if (localized.length == 0) {
        // Try the fallback locale
        NSLocale *USLocale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
        localized = [USLocale displayNameForKey:NSLocaleCountryCode value:self.ISO];
    }
    if (localized.length == 0) {
        // Return something instead of just @c nil
        return [self.ISO uppercaseString];
    }
    return localized;
}

- (NSString *)e164PrefixString
{
    return [NSString stringWithFormat:@"+%@", self.e164, nil];
}

@end


@implementation NSString (PhoneNumber)

+ (NSString *)phoneNumberStringWithE164:(NSNumber *)e164 number:(NSString *)number
{
    NSString *phoneNumber = [NSString stringWithFormat:@"+%@%@", e164, number];
    return phoneNumber;
}

@end
NS_ASSUME_NONNULL_END

