@interface SpringBoard
+(id)sharedApplication;
-(id)statusBar;
@end

@interface SBChevronView : UIView
@end

@interface SBLockScreenView
-(double)_percentScrolled;
-(SBChevronView*)topGrabberView;
@end

static UIStatusBarTimeItemView* timeItemView;
static BOOL isFading = NO;
static BOOL isLocked = NO;
static BOOL isTopGrabberHidden = NO;
static double percentScrolled = 0.0;
static CGFloat timeLabelAlpha;

void setViewAlpha(UIView* view, CGFloat alpha) {
	if (view) {
		for (UIView* v in view.subviews) {
			v.alpha = alpha;
		}
		view.alpha = alpha;
	}
}

void setTimeViewAlpha(UIView* view) {
	if (!isLocked || (isTopGrabberHidden && timeLabelAlpha == 0.0)) {
		setViewAlpha(view, 1.0);
	} else if (isFading || percentScrolled > 0.0) {
		setViewAlpha(view, percentScrolled);
	} else {
		setViewAlpha(view, 0.0);
	}
}

void setTimeItemView() {
	timeItemView = nil;
	UIStatusBar* statusBar = [(SpringBoard*)[%c(SpringBoard) sharedApplication] statusBar];
	UIStatusBarForegroundView* foregroundView = MSHookIvar<UIStatusBarForegroundView*>(statusBar, "_foregroundView");
	for (UIView* v in foregroundView.subviews) {
		if ([v isKindOfClass:[%c(UIStatusBarTimeItemView) class]]) {
			timeItemView = (UIStatusBarTimeItemView*)v;
			break;
		}
	}
}

%hook SBLockScreenViewController
-(BOOL)shouldShowLockStatusBarTime {
	return YES;
}

-(void)lockScreenView:(id)view didScrollToPage:(long long)page {
	%orig;

	if (page == 0 && timeItemView) {
		[UIView animateWithDuration:0.5 animations:^{
			percentScrolled = 1.0;
			setTimeItemView();
			setTimeViewAlpha(timeItemView);
		}];
	}
}
%end

%hook UIStatusBarLayoutManager
-(id)_viewForItem:(id)item {
	UIView* view = %orig;

	if ([view isKindOfClass:[%c(UIStatusBarTimeItemView) class]]) {
		setTimeItemView();
		setTimeViewAlpha(timeItemView);
	}

	return view;
}
%end

%hook SBLockScreenView
-(void)setTopGrabberHidden:(BOOL)hidden forRequester:(id)requester {
	%orig;

	if (hidden) {
		isTopGrabberHidden = YES;
	} else {
		SBChevronView* topGrabberView = [self topGrabberView];
		if (topGrabberView.alpha == 0.0) {
			isTopGrabberHidden = YES;
		} else {
			isTopGrabberHidden = NO;
		}
	}
	setTimeItemView();
	setTimeViewAlpha(timeItemView);
}

-(void)_beginCrossfadingFakeStatusBars {
	%orig;

	isFading = YES;
	setTimeItemView();
}

-(void)_endCrossfadingFakeStatusBars {
	%orig;

	isFading = NO;
	percentScrolled = [self _percentScrolled];
}

-(void)_updateFakeStatusBarsForPercentScrolled:(double)percent {
	%orig;

	if (!isLocked || !isFading)
		return;

	percentScrolled = percent;
	setTimeViewAlpha(timeItemView);
}
%end

%hook SBLockScreenManager
-(void)_postLockCompletedNotification:(BOOL)locked {
	%orig;

	isLocked = locked;
}
%end

%hook SBFLockScreenDateView
-(void)_updateLabelAlpha {
	%orig;

	UILabel* timeLabel = MSHookIvar<UILabel*>(self, "_timeLabel");
	timeLabelAlpha = timeLabel.alpha;
	setTimeItemView();
	setTimeViewAlpha(timeItemView);
}
%end

