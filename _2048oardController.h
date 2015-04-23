#import <UIKit/UIKit.h>

@interface _2048oardController : NSObject <UIGestureRecognizerDelegate> {
}
@property (nonatomic, retain) NSMutableArray *preview;

// UI
@property (nonatomic, assign, getter=isShowing) BOOL showing;
@property (nonatomic, retain) UIWindow *overlay;
@property (nonatomic, retain) UIWindow *board;
@property (nonatomic, retain) UIView *gameOverScreen;

@property (nonatomic, assign) id folderToOpen;

- (void)show;
- (void)dismiss;

@end
