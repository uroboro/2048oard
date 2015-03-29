#ifndef INTERFACES_H
#define INTERFACES_H

#import <UIKit/UIKit.h>

@interface SBIconController : NSObject
+(id)sharedInstance;
-(id)model;
-(id)openFolder;
-(char)hasOpenFolder;
-(char)hasAnimatingFolder;
-(void)closeFolderAnimated:(char)arg1;
-(void)openFolder:(id)arg1 animated:(char)arg2;
-(id)currentRootIconList;
@end

@interface SBIconModel : NSObject
-(id)leafIcons;
@end

@interface SBIconListView : UIView
-(id)icons;
@end

@interface SBIconViewMap : NSObject
+(id)homescreenMap;
-(id)mappedIconViewForIcon:(id)arg1;
@end

@interface SBApplication : NSObject
@end

@interface SBApplicationController : NSObject
+(id)sharedInstance;
-(id)applicationWithDisplayIdentifier:(id)arg1;
-(id)applicationWithBundleIdentifier:(id)arg1;
@end

@interface SBIcon : NSObject
-(NSInteger)badgeValue;
-(id)badgeNumberOrString;
-(void)setBadge:(id)arg1;
-(id)application;
-(NSString *)displayName;
-(id)getIconImage:(int)arg1;
-(void)reloadIconImagePurgingImageCache:(char)arg1;
-(char)isApplicationIcon;
-(char)isBookmarkIcon;
-(char)isLeafIcon;
-(char)isDownloadingIcon;
-(char)isPrintStatusIcon;
-(char)isNewsstandApplicationIcon;
-(char)isNewsstandIcon;
-(char)isFolderIcon;
@end

@interface SBPlaceholderIcon : SBIcon
@end

@interface SBFolderIcon : SBIcon
@end

@interface SBNewsstandIcon : SBFolderIcon
@end

@interface SBLeafIcon : SBIcon
@end

@interface SBBookmarkIcon : SBLeafIcon
@end

@interface SBDownloadingIcon : SBLeafIcon
@end

@interface SBPrintStatusIcon : SBLeafIcon
@end

@interface SBApplicationIcon : SBLeafIcon
-(id)initWithApplication:(id)arg1;
@end

@interface SBCalendarApplicationIcon : SBApplicationIcon
@end

@interface SBWeatherApplicationIcon : SBApplicationIcon
@end

@interface SBWebApplicationIcon : SBApplicationIcon
@end

@interface SBUserInstalledApplicationIcon : SBApplicationIcon
@end

@interface SBNewsstandApplicationIcon : SBUserInstalledApplicationIcon
@end

@interface SBIconImageView : UIImageView
@end

@interface SBIconView : UIView
@property (nonatomic, assign) SBIcon *icon;
+(CGSize)defaultIconSize;
+(CGSize)defaultIconImageSize;
-(id)initWithDefaultSize;
-(SBIconImageView *)iconImageView;
-(void)updateLabel; // < iOS 7
-(void)_updateLabel; // >= iOS 7
@end

@interface SBDownloadingIconView : SBIconView
@end

@interface SBFolderIconView : SBIconView
@end

@interface SBNewsstandIconView : SBFolderIconView
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
- (void)_presentBannerForItem:(id)arg1; // <= kCFCoreFoundationVersionNumber_iOS_5_1
- (id)newBannerViewForItem:(id)arg1; // > kCFCoreFoundationVersionNumber_iOS_5_1
@end

@interface SBBulletinBannerItem : NSObject
+ (id)itemWithBulletin:(id)arg1; // <= kCFCoreFoundationVersionNumber_iOS_5_1
+ (id)itemWithBulletin:(id)arg1 andObserver:(id)arg2; // > kCFCoreFoundationVersionNumber_iOS_5_1
@end

@interface SBBannerController : NSObject
+ (id)sharedInstance;
- (void)_presentBannerView:(id)arg1; // > kCFCoreFoundationVersionNumber_iOS_5_1
@end

#endif /* INTERFACES_H */