#import <CoreGraphics/CGGeometry.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define indexForPosition_(row, column, columnsPerRow) (row * columnsPerRow + column)
#define indexForPosition(row, column) indexForPosition_(row, column, 4)
#define positionForIndex(idx) idx/4, idx%4

CG_EXTERN CGRect frameForPosition(NSInteger row, NSInteger column);
CG_EXTERN NSMutableArray *randomArrayOf16Numbers();
CG_EXTERN NSArray *processArrayWithDirection(NSArray *array, UISwipeGestureRecognizerDirection direction);
CG_EXTERN void addRandomValueToArray(NSMutableArray *array);
CG_EXTERN NSInteger highestNumberInArray(NSArray *array);
CG_EXTERN BOOL canMakeMovements(NSArray *array);