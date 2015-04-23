#include <dlfcn.h>
#include <objc/runtime.h>
#import <libactivator/libactivator.h>

#import "_2048oardListener.h"

#import "_2048oardController.h"

static NSString *bundleID = @"com.uroboro.2048oard";

static LAActivator *_LASharedActivator;

static void loadActivator() {
	NSLog(@"X2048:: attempting to load libactivator");
	void *la = dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	if (!(char *)la) {
		NSLog(@"X2048:: failed to load libactivator");
	}
	NSLog(@"X2048:: libactivator is installed");
	_LASharedActivator = [objc_getClass("LAActivator") sharedInstance];
}

@implementation _2048oardListener

+ (id)sharedInstance {
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}

+ (void)load {
	loadActivator();
	[self sharedInstance];
}

- (id)init {
	if ([super init]) {
		// Register our listener
		if (_LASharedActivator) {
			if (![_LASharedActivator hasSeenListenerWithName:bundleID]) {
				[_LASharedActivator assignEvent:[objc_getClass("LAEvent") eventWithName:@"libactivator.volume.both.press"] toListenerWithName:bundleID];
			}
			if (_LASharedActivator.isRunningInsideSpringBoard) {
				[_LASharedActivator registerListener:self forName:bundleID];
			}
		}

	}
	return self;
}

- (void)dealloc {
	if (_LASharedActivator) {
		if (_LASharedActivator.runningInsideSpringBoard) {
			[_LASharedActivator unregisterListenerWithName:bundleID];
		}
	}
	[super dealloc];
}

// LAListener protocol methods

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	// Called when we receive event
	_2048oardController *b = [_2048oardController sharedInstance];
	if (!b.isShowing) {
		[[_2048oardController sharedInstance] show];
	} else {
		[[_2048oardController sharedInstance] dismiss];
	}
	[event setHandled:YES];
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
	// Called when event is escalated to a higher event
	// (short-hold sleep button becomes long-hold shutdown menu, etc)
	[[_2048oardController sharedInstance] dismiss];
}

- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event {
	// Called when some other listener received an event; we should cleanup
	[[_2048oardController sharedInstance] dismiss];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event {
	// Called when the home button is pressed.
	// If (and only if) we are showing UI, we should dismiss it and call setHandled:
	[[_2048oardController sharedInstance] dismiss];
}

// Metadata
// Group name
- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
	return @"Games";
}
// Listener name
- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
	return @"2048";
}
// Listener description
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
	return @"Play 2048 on SB";
}

// Group assignment filtering
- (NSArray *)activator:(LAActivator *)activator requiresExclusiveAssignmentGroupsForListenerName:(NSString *)listenerName {
	return [NSArray array];
}


@end
