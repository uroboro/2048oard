#import <Preferences/Preferences.h>

@interface _2048oardListController: PSListController {
}
@end

@implementation _2048oardListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"_2048oard" target:self] retain];
	}
	return _specifiers;
}
@end

// vim:ft=objc
