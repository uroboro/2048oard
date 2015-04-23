#import <UIKit/UIKit.h>
#import <libactivator/libactivator.h>
#import "_2048oardController.h"

@interface _2048oardListener : NSObject <LAListener> {
}
@property (nonatomic, assign) _2048oardController *boardController;
@end
