#import <UIKit/UIKit.h>

@interface _2048oardController : NSObject <UIGestureRecognizerDelegate> {
}
@property (nonatomic, readonly, getter=isShowing) BOOL showing;

- (void)show;
- (void)dismiss;

@end
