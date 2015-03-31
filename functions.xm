#include "interfaces.h"
#import "functions.h"

CG_EXTERN CGRect frameForPosition(NSInteger row, NSInteger column) {
	CGSize s = [%c(SBIconView) defaultIconSize];
	int offsets[4] = {0, 1, 3, 4};
	int xPadding = ([[UIApplication sharedApplication] keyWindow].frame.size.width - 4 * s.width) / 5;
	int yPadding = 16;

	CGFloat x = xPadding + (xPadding + s.width) * column + offsets[column];
	CGFloat y = yPadding + (yPadding + s.height) * row;

	return CGRectMake(x, y, s.width, s.height);
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
	for ((!xy ? (y = ym) : (x = xm)); (!xy ? (y != yM) : (x != xM)); y += !xy * yd, x +=  xy * xd) {
		NSMutableArray *temp = [NSMutableArray new];
		for (( xy ? (y = ym) : (x = xm)); ( xy ? (y != yM) : (x != xM)); y +=  xy * yd, x += !xy * xd) {
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
			if (![array[i] intValue]) {
				id obj = array[i];
				array[i] = array[i+1];
				array[i+1] = obj;
			}
		}
	}

	return array;
}

static NSArray *compressedArrayIfNeeded(NSArray *icons) {
	if (!icons) {
		return nil;
	}
	//initial sort
	//move all zero/null values to the end of the array
	NSArray *array = sinkIcons(icons);

	NSMutableArray *compressedIcons = [NSMutableArray new];
	NSInteger c = array.count;
	for (int i = 0; i < c; i++) {
		NSInteger currValue = [array[i] intValue];

		// Skip if current value is 0
		if (!currValue) {
			continue;
		}

		NSInteger nextValue = (i + 1 >= c) ? 0 : [array[i+1] intValue];

		// Add current value if next is 0 or doesn't exist
		if (!nextValue) {
			[compressedIcons addObject:@(currValue)];
			continue;
		}

		// Compress if equal
		if (currValue == nextValue) {
			[compressedIcons addObject:@(currValue * 2)];
			[compressedIcons addObject:@0];
			i++;
			continue;
		}

		// Just add if they differ
		[compressedIcons addObject:@(currValue)];
	}

	//sort the items
	//using the above, we will retain zeroes in the middle of the sequence
	//we want 4 4 0 0, not 4 0 4 0
	//move zeroes to the end again
	NSMutableArray *result = [sinkIcons(compressedIcons) mutableCopy];
	[compressedIcons release];
	//ensure we always return 4 items
	while (result.count < 4) {
		[result addObject:@0];
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
		[result addObject:compressedArrayIfNeeded(array)];
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
	for ((!xy ? (y = ym) : (x = xm)); (!xy ? (y != yM) : (x != xM)); y += !xy * yd, x +=  xy * xd) {
		for (( xy ? (y = ym) : (x = xm)); ( xy ? (y != yM) : (x != xM)); y +=  xy * yd, x += !xy * xd) {
			[a addObject:array[y][x]];
		}
	}

	return [a autorelease];
}

CG_EXTERN NSArray *processArrayWithDirection(NSArray *array, UISwipeGestureRecognizerDirection direction) {
	NSArray *arrays = sinkedArraysWithDirection(array, direction);
	return composedArrayWithDirection(arrays, direction);
}

CG_EXTERN void addRandomValueToArray(NSMutableArray *array) {
	if (!array) {
		return;
	}

	NSInteger iconsToPlace = 1 + ((array.count < 12) && (arc4random_uniform(100) >= 35));

	for (int i = 0; i < iconsToPlace; i++) {
		//find out how many zero values they have so we can determine random range
		//we store their indexes in an array so we don't have to find the index later
		NSMutableArray *zeroTracker = [NSMutableArray new];

		[array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if (![obj intValue]) {
				[zeroTracker addObject:@(idx)];
			}
		}];

		//place a random icon at a random one of the null values
		NSNumber *zeroIndex = zeroTracker[arc4random_uniform(zeroTracker.count)];
		NSInteger newValue = 2 << (arc4random_uniform(4) == 3);

		[array replaceObjectAtIndex:[zeroIndex intValue] withObject:@(newValue)];
		[zeroTracker release];
	}
}

CG_EXTERN NSMutableArray *randomArrayOf16Numbers() {
	NSMutableArray *array = [NSMutableArray new];
	for (int i = 0; i < 16; i++) {
		NSInteger j = arc4random_uniform(10);
		NSInteger newValue = (j < 7) ? 0 : (j < 9) ? 2 : 4;
		[array addObject:@(newValue)];
	}
	return array;
}

CG_EXTERN NSInteger highestNumberInArray(NSArray *array) {
	__block NSInteger i = 0;
	if (!array) {
		return i;
	}
	[array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSInteger value = [(NSNumber *)obj intValue];
		if (value > i) {
			i = value;
		}
	}];
	return i;
}

CG_EXTERN BOOL canMakeMovements(NSArray *array) {
	if (!array) {
		return NO;
	}
	NSArray *aRight = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionRight);
	NSArray *aLeft = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionLeft);
	NSArray *aUp = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionUp);
	NSArray *aDown = processArrayWithDirection(array, UISwipeGestureRecognizerDirectionDown);
	BOOL c0 = [aRight isEqualToArray:aLeft];
	BOOL c1 = [aUp isEqualToArray:aDown];
	return !((c0 && c1) ? [aRight isEqualToArray:aUp] : NO);
}
