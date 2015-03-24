#include <objc/runtime.h>
#include <dispatch/dispatch.h>
#import <libactivator/libactivator.h>
#import <UIKit/UIKit.h>

#include "interfaces.h"

#define indexForPosition_(row, column, columnsPerRow) (row * columnsPerRow + column)
#define indexForPosition(row, column) indexForPosition_(row, column, 4)

#define ICONS_STUFF 0

@interface _2048oard : NSObject <LAListener> {
}
@property (nonatomic, retain) NSMutableArray *currentLayout;
@property (nonatomic, retain) NSMutableArray *preview;
@property (nonatomic, retain) NSMutableArray *badgeValues;

// UI
@property (nonatomic, assign) BOOL waitingToShow;
@property (nonatomic, assign) BOOL showing;
@property (nonatomic, retain) UIWindow *overlay;
@property (nonatomic, retain) UIWindow *board;

@property (nonatomic, assign) id folderToOpen;

+ (id)sharedInstance;

- (void)show;
- (void)dismiss;
- (BOOL)act;

@end

static NSString *NSArrayDescriptionInSingleLine(NSArray *a) {
	if (!a) {
		return nil;
	}
	return [NSString stringWithFormat:@"@[%@]", [a componentsJoinedByString:@","]];
}

static CGPoint originForPosition(NSInteger row, NSInteger column) {
	SBIconController *ic = (SBIconController *)[%c(SBIconController) sharedInstance];
	NSArray *icons = [[ic currentRootIconList] icons];
	SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];
	SBIconView *iconSample = [iconMap mappedIconViewForIcon:[icons objectAtIndex:0]];
	CGFloat iconWidth = iconSample.frame.size.width;
	CGFloat iconHeight = iconSample.frame.size.height;
	int offsets[4] = {0, 1, 3, 4};
	int xPadding = ([[UIApplication sharedApplication] keyWindow].frame.size.width - 4 * iconWidth) / 5;
	int yPadding = 16;

	CGFloat x = xPadding + (xPadding + iconWidth) * column + offsets[column];
	CGFloat y = yPadding + (yPadding + iconHeight) * row;

	return CGPointMake(x, y);
}

static NSMutableArray *arrayOf16FromCurrentIconList() {
	SBIconController *ic = (SBIconController *)[%c(SBIconController) sharedInstance];
	NSArray *icons = [[ic currentRootIconList] icons];
	SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];
	NSMutableArray *array = [NSMutableArray new];
	[icons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		SBIcon *icon = (SBIcon *)obj;
		SBIconView *iconView = [iconMap mappedIconViewForIcon:icon];

		Class iconViewClass = Nil;
		if ([icon isFolderIcon]) {
			iconViewClass = %c(SBFolderIconView);
		} else if ([icon isNewsstandIcon]) {
			iconViewClass = %c(SBNewsstandIconView);
		} else if ([icon isDownloadingIcon]) {
			iconViewClass = %c(SBDownloadingIconView);
		} else {
			iconViewClass = %c(SBIconView);
		}
		SBIconView *newIconView = [[iconViewClass alloc] initWithDefaultSize];
		[newIconView setIcon:icon];
		newIconView.frame = iconView.frame;

		[array addObject:newIconView];
	}];
	while ([array count] < 16) {
		[array addObject:[NSNull null]];
	}
	while ([array count] > 16) {
		[array removeLastObject];
	}
	return [array autorelease];
}

static NSArray *arraysWithDirection(NSArray *array, UISwipeGestureRecognizerDirection direction) {
	if (!array) {
		return nil;
	}

	NSInteger xm, xM, xd, ym, yM, yd;
	NSInteger xy; // first loop is for x
	switch (direction) {
	case UISwipeGestureRecognizerDirectionRight:
		//top to bottom, 0 at right
		xy = 0;
		ym = 0; yM = 4; yd = 1;
		xm = 3; xM = -1; xd = -1;
	break;
	case UISwipeGestureRecognizerDirectionLeft:
		//top to bottom, 0 at left
		xy = 0;
		ym = 0; yM = 4; yd = 1;
		xm = 0; xM = 4; xd = 1;
	break;
	case UISwipeGestureRecognizerDirectionUp:
		//left to right, 0 at top
		xy = 1;
		ym = 0; yM = 4; yd = 1;
		xm = 0; xM = 4; xd = 1;
	break;
	case UISwipeGestureRecognizerDirectionDown:
		//left to right, 0 at bottom
		xy = 1;
		ym = 3; yM = -1; yd = -1;
		xm = 0; xM = 4; xd = 1;
	break;
	default:
		return nil;
	}

	NSMutableArray *a = [NSMutableArray new];
	NSInteger x, y;
//	printf("x:%d,%d,%d\n", xm, xd, xM);
//	printf("y:%d,%d,%d\n", ym, yd, yM);
//	printf("d:%d\n", direction);
	for ((!xy ? (y = ym) : (x = xm)); (!xy ? (y != yM) : (x != xM)); y += !xy * yd, x +=  xy * xd) {
		NSMutableArray *temp = [NSMutableArray new];
		for (( xy ? (y = ym) : (x = xm)); ( xy ? (y != yM) : (x != xM)); y +=  xy * yd, x += !xy * xd) {
//			printf("%d ", indexForPosition(y, x));
			[temp addObject:array[indexForPosition(y, x)]];
		}
		[a addObject:temp];
		[temp release];
	}

	return [a autorelease];
}

static NSArray *sinkIcons(NSArray *icons) {
	if (!icons) {
		return nil;
	}

	NSMutableArray *array = [icons mutableCopy];
	int c = array.count - 1;
	for (int j = 0; j < c; j++) {
		for (int i = 0; i < c - j; i++) {
			int condition;
			if ([array[i] isKindOfClass:[NSNumber class]]) {
				condition = [array[i] intValue] == 0;
			} else {
				condition = (array[i] == [NSNull null] || [((SBIconView *)array[i]).icon badgeValue] == 0);
			}
			if (condition) {
				id obj = array[i];
				array[i] = array[i+1];
				array[i+1] = obj;
			}
		}
	}

	return array;
}

static NSArray *badgeCompressedIconsIfNeeded(NSArray *icons) {
	if (!icons) {
		return nil;
	}
	//initial sort
	//move all zero/null values to the end of the array
	NSArray *array = sinkIcons(icons);

	NSMutableArray *compressedIcons = [NSMutableArray new];
	BOOL isNSNumber = NO;
	//we don't need to worry about the last item in the array, so skip it
	for (int i = 0; i < array.count-1; i++) {
		int condition;
		if ([array[i] isKindOfClass:[NSNumber class]]) {
			isNSNumber = YES;
			condition = [array[i] intValue] == 0;
		} else {
			condition = (array[i] == [NSNull null] || [((SBIconView *)array[i]).icon badgeValue] == 0);
		}
		if (condition) {
			continue;
		}

		NSInteger firstValue, aboveValue;
		if (isNSNumber) {
			firstValue = [array[i] intValue];
			aboveValue = [array[i+1] intValue];
		} else {
			firstValue = [((SBIconView *)array[i]).icon badgeValue];
			aboveValue = (array[i+1] == [NSNull null]) ? 0 : [((SBIconView *)array[i+1]).icon badgeValue];
		}
		if (firstValue != aboveValue) {
			if (isNSNumber) {
				[compressedIcons addObject:@(firstValue)];
			} else {
				[((SBIconView *)array[i]).icon setBadge:[NSString stringWithFormat:@"%d", firstValue]];
				[compressedIcons addObject:array[i]];
			}
			continue;
		}

		if (isNSNumber) {
			[compressedIcons addObject:@(firstValue * 2)];
			[compressedIcons addObject:@0];
		} else {
			[((SBIconView *)array[i]).icon setBadge:[NSString stringWithFormat:@"%d", firstValue * 2]];
			[compressedIcons addObject:array[i]];
			[compressedIcons addObject:[NSNull null]];
		}
		//we're done with both this item and the next item, so skip the next one
		i++;
	}

	//sort the items
	//using the above, we will retain zeroes in the middle of the sequence
	//we want 4 4 0 0, not 4 0 4 0
	//move zeroes to the end again
	NSMutableArray *result = [sinkIcons(compressedIcons) mutableCopy];
	//ensure we always return 4 items
	while (result.count < 4) {
		if (isNSNumber) {
			[result addObject:@0];
		} else {
			[result addObject:[NSNull null]];
		}
	}

	return result;
}

static NSArray *sinkedArraysWithDirection(NSArray *array, UISwipeGestureRecognizerDirection direction) {
	NSArray *arrays = arraysWithDirection(array, direction);
	if (!arrays) {
		return nil;
	}
	NSMutableArray *result = [NSMutableArray new];
	for (NSArray *array in arrays) {
		[result addObject:badgeCompressedIconsIfNeeded(array)];
	}
	return [result autorelease];
}

static NSArray *composedArrayWithDirection(NSArray *array, UISwipeGestureRecognizerDirection direction) {
	if (!array) {
		return nil;
	}

	NSInteger xm, xM, xd, ym, yM, yd;
	NSInteger xy; // first loop is for x
	switch (direction) {
	case UISwipeGestureRecognizerDirectionRight:
		//top to bottom, 0 at right
		xy = 0;
		ym = 0; yM = 4; yd = 1;
		xm = 3; xM = -1; xd = -1;
	break;
	case UISwipeGestureRecognizerDirectionLeft:
		//top to bottom, 0 at left
		xy = 0;
		ym = 0; yM = 4; yd = 1;
		xm = 0; xM = 4; xd = 1;
	break;
	case UISwipeGestureRecognizerDirectionUp:
		//left to right, 0 at top
		xy = 1;
		ym = 0; yM = 4; yd = 1;
		xm = 0; xM = 4; xd = 1;
	break;
	case UISwipeGestureRecognizerDirectionDown:
		//left to right, 0 at bottom
		xy = 1;
		ym = 0; yM = 4; yd = 1;
		xm = 3; xM = -1; xd = -1;
	break;
	default:
		return nil;
	}

	NSMutableArray *a = [NSMutableArray new];
	NSInteger x, y;
//	printf("x:%d,%d,%d\n", xm, xd, xM);
//	printf("y:%d,%d,%d\n", ym, yd, yM);
//	printf("d:%d\n", direction);
	for ((!xy ? (y = ym) : (x = xm)); (!xy ? (y != yM) : (x != xM)); y += !xy * yd, x +=  xy * xd) {
		for (( xy ? (y = ym) : (x = xm)); ( xy ? (y != yM) : (x != xM)); y +=  xy * yd, x += !xy * xd) {
//			printf("%d ", indexForPosition(y, x));
			[a addObject:array[y][x]];
		}
	}

	return [a autorelease];
}

static NSArray *processArrayWithDirection(NSArray *array, UISwipeGestureRecognizerDirection direction) {
	NSArray *arrays = sinkedArraysWithDirection(array, direction);
	return composedArrayWithDirection(arrays, direction);
}




@implementation _2048oard

+ (id)sharedInstance {
	static id sharedInstance = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedInstance = [self new];
	});
	return sharedInstance;
}

+ (void)load {
	// Register our listener
	if (LASharedActivator.isRunningInsideSpringBoard) {
		[LASharedActivator registerListener:[self sharedInstance] forName:@"com.uroboro.2048oard"];
	}
}

- (id)init {
	if ([super init]) {
	}
	return self;
}

- (void)dealloc {
	if (LASharedActivator.runningInsideSpringBoard) {
		[LASharedActivator unregisterListenerWithName:@"com.uroboro.2048oard"];
	}
	[super dealloc];
}

- (void)saveIconBadges {
	_badgeValues = [NSMutableArray new];
	SBIconController *ic = [%c(SBIconController) sharedInstance];
	NSArray *icons = [[ic currentRootIconList] icons];
	[icons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		SBIcon *icon = (SBIcon *)obj;
		NSInteger badgeValue = [icon badgeValue];
		[_badgeValues addObject:@(badgeValue)];
	}];
}

- (void)restoreIconBadges {
	if (!_badgeValues) {
		return;
	}
	SBIconController *ic = [%c(SBIconController) sharedInstance];
	NSArray *icons = [[ic currentRootIconList] icons];
	[icons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		SBIcon *icon = (SBIcon *)obj;
		NSInteger badgeValue = [[_badgeValues objectAtIndex:idx] intValue];
		[icon setBadge:badgeValue?[@(badgeValue) description]:nil];
	}];
	[_badgeValues release];
	_badgeValues = nil;
}

- (void)setIconViewsAlpha:(CGFloat)a {
	SBIconController *ic = [%c(SBIconController) sharedInstance];
	NSArray *icons = [[ic currentRootIconList] icons];
	SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];
	[icons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		SBIcon *icon = (SBIcon *)obj;
		UIView *iconView = [iconMap mappedIconViewForIcon:icon];
		[iconView setAlpha:a];
	}];
}

- (void)hideIcons {
	[self setIconViewsAlpha:0];
}

- (void)revealIcons {
	[self setIconViewsAlpha:1];
}

- (void)show {
	_preview = [@[
	 @2 ,@2 ,@0 ,@0
	,@0 ,@2 ,@0 ,@0
	,@0 ,@0 ,@2 ,@0
	,@0 ,@0 ,@4 ,@2] mutableCopy];
	NSLog(@"\033[32mX_2048oard: %@\033[0m", NSArrayDescriptionInSingleLine(_preview));

	[self saveIconBadges];
	[self hideIcons];

//	_currentLayout = arrayOf16FromCurrentIconList();
	NSLog(@"\033[32mX_2048oard: %@\033[0m", NSArrayDescriptionInSingleLine(_currentLayout));

#if ICONS_STUFF
	SBIconController *ic = [%c(SBIconController) sharedInstance];
	NSArray *icons = [[ic currentRootIconList] icons];
	SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];
	[icons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		SBIcon *icon = (SBIcon *)obj;
		[icon setBadge:[@2 description]];
	}];
#endif /* ICONS_STUFF */
	_board = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	[_board setWindowLevel:UIWindowLevelAlert-2];
	[_board setAutoresizesSubviews:YES];
	[_board setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];

//	[self updateBoard];
	[_board setHidden:NO];

	_overlay = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	[_overlay setWindowLevel:UIWindowLevelAlert-1];
	[_overlay setAutoresizesSubviews:YES];
	[_overlay setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
#if DEBUG
	[_overlay setBackgroundColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.3]];
#endif
	for (UISwipeGestureRecognizerDirection d = UISwipeGestureRecognizerDirectionRight; d <= UISwipeGestureRecognizerDirectionDown; d <<= 1) {
		UISwipeGestureRecognizer *sgr = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
		sgr.direction = d;
		[_overlay addGestureRecognizer:sgr];
	}

	[_overlay makeKeyAndVisible];

}

- (void)updateBoard {
	if (!_board) {
		return;
	}
	for (UIView *v in _board.subviews) {
		[v removeFromSuperview];
	}
	if (!_currentLayout) {
		return;
	}
	[_currentLayout enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if (obj == [NSNull null] || [obj isKindOfClass:[NSNumber class]]) {
			return;
		}
#if ICONS_STUFF
		SBIconView *iconView = (SBIconView *)obj;
		CGPoint p = originForPosition(idx/4, idx%4);
		CGSize s = iconView.frame.size;
		iconView.frame = CGRectMake(p.x, p.y, s.width, s.height);
		[_board addSubview:iconView];
#endif /* ICONS_STUFF */
	}];
}

- (void)dismiss {
	if (_currentLayout) {
		[_currentLayout release];
		_currentLayout = nil;
	}
	if (_board) {
		[_board setHidden:YES];
		[_board release];
		_board = nil;
	}

	if (_overlay) {
		[_overlay setHidden:YES];
		[_overlay release];
		_overlay = nil;
	}

	[self restoreIconBadges];
	[self revealIcons];
}

- (BOOL)act {
	// Ensures alert view is dismissed
	// Returns YES if alert was visible previously
	SBIconController *ic = [%c(SBIconController) sharedInstance];

	if (!_showing) {
		_showing = YES;

		if ([ic hasOpenFolder]) {
			_folderToOpen = [ic openFolder];
			[ic closeFolderAnimated:YES];

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.55 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				[self show];
			});

		} else {
			[self show];
		}
	} else {
		_showing = NO;
		[self dismiss];

		if (_folderToOpen) {
			[ic openFolder:_folderToOpen animated:YES];
			_folderToOpen = nil;
		}
	}
	return _showing;
}

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)gestureRecognizer {
	UISwipeGestureRecognizerDirection dir = gestureRecognizer.direction;
#if DEBUG
	switch (dir) {
	case UISwipeGestureRecognizerDirectionRight:
		[_overlay setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:0.3]];
	break;
	case UISwipeGestureRecognizerDirectionLeft:
		[_overlay setBackgroundColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:0.3]];
	break;
	case UISwipeGestureRecognizerDirectionUp:
		[_overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:1 alpha:0.3]];
	break;
	case UISwipeGestureRecognizerDirectionDown:
		[_overlay setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:0 alpha:0.3]];
	break;
	}
#endif

	_preview = [processArrayWithDirection(_preview, dir) mutableCopy];
	NSLog(@"\033[32mX_2048oard: %@\033[0m", NSArrayDescriptionInSingleLine(_preview));
	
	FILE *fp = fopen("/User/2048oard.txt", "w");
	for (int j = 0; j < 16; j++) {
		fprintf(fp, "%d%c", [_preview[j] intValue], (j%4==3)?'\n':' ');
	}
	fclose(fp);
//	[self updateBoard];
}

// LAListener protocol methods

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	// Called when we receive event
	if ([self act]) {
		[event setHandled:YES];
	}
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
	// Called when event is escalated to a higher event
	// (short-hold sleep button becomes long-hold shutdown menu, etc)
	_showing = YES;
	[self act];
}

- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event {
	// Called when some other listener received an event; we should cleanup
	_showing = YES;
	[self act];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event {
	// Called when the home button is pressed.
	// If (and only if) we are showing UI, we should dismiss it and call setHandled:
	_showing = YES;
	[self act];
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
/* Group assignment filtering
- (NSArray *)activator:(LAActivator *)activator requiresExclusiveAssignmentGroupsForListenerName:(NSString *)listenerName {
	return [NSArray array];
}
*/

@end
