#ifndef INTERFACES_H
#define INTERFACES_H

#import <UIKit/UIKit.h>

@interface SBIconListView : UIView
- (id)icons;
@end

@interface SBIconController : NSObject
+ (id)sharedInstance;
- (id)model;
- (id)openFolder;
- (BOOL)hasOpenFolder;
- (BOOL)hasAnimatingFolder;
- (void)closeFolderAnimated:(BOOL)animated;
- (void)openFolder:(id)arg1 animated:(BOOL)animated;
- (SBIconListView *)currentRootIconList;
@end

@interface SBIconModel : NSObject
- (void)loadAllIcons;
@end

@interface SBIconViewMap : NSObject
+ (id)homescreenMap;
- (id)mappedIconViewForIcon:(id)arg1;
@end

@interface SBIcon : NSObject
- (NSInteger)badgeValue;
- (id)badgeNumberOrString;
- (void)setBadge:(id)arg1;
- (NSString *)displayName;
- (id)getIconImage:(NSInteger)arg1;
- (void)reloadIconImagePurgingImageCache:(BOOL)arg1;
@end

@interface SBIconView : UIView
@property (nonatomic, assign) SBIcon *icon;
+ (CGSize)defaultIconSize;
+ (CGSize)defaultIconImageSize;
- (id)initWithDefaultSize;
- (void)updateLabel; // < iOS 7
- (void)_updateLabel; // >= iOS 7
@end

@interface BBBulletinRequest : NSObject {}
@property (nonatomic, copy) NSString *bulletinID;
@property (nonatomic, copy) NSString *sectionID;
@property (nonatomic, copy) NSString *recordID;
@property (nonatomic, copy) NSString *publisherBulletinID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, assign) int primaryAttachmentType;
@end

@interface SBBulletinBannerController : NSObject
+ (id)sharedInstance;
- (void)_presentBannerForItem:(id)arg1; // iOS 5
- (id)newBannerViewForItem:(id)arg1; // iOS 6
- (void)observer:(id)arg1 addBulletin:(BBBulletinRequest *)arg2 forFeed:(NSUInteger)arg3; // iOS 7-8
@end

@interface SBBulletinBannerItem : NSObject
+ (id)itemWithBulletin:(id)arg1; // iOS 5
+ (id)itemWithBulletin:(id)arg1 andObserver:(id)arg2; // iOS 6
@end

@interface SBBannerController : NSObject
+ (id)sharedInstance;
- (void)_presentBannerView:(id)arg1; // iOS 7-8
@end

#endif /* INTERFACES_H */