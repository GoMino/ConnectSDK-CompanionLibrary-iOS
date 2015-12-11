//
//  CastDeviceSelectionView.m
//
//  Created by Fabien BOURDON on 30/06/2014.
//  Copyright (c) 2014 Rémi ROCARIES. All rights reserved.
//

#import "CastDeviceSelectionView.h"

#define MARGIN 5
#define MARGIN_BETWEEN_ELEMENTS 20

@interface CastDeviceSelectionView ()

@property (nonatomic, retain) NSMutableArray *buttons;
@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet UIView *backview;
@property (retain, nonatomic) IBOutlet UILabel *title;
@property (retain, nonatomic) IBOutlet UIButton *closeButton;
@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (assign, nonatomic) CGFloat maxHeight;

@end


@implementation CastDeviceSelectionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.buttons = [NSMutableArray array];
        self.maxHeight = ceilf(2*(self.frame.size.height/3));
        UITapGestureRecognizer *tapBack = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(close:)];
        [self.backview addGestureRecognizer:tapBack];
    }
    return self;
}


- (void)addButton:(CastButton *)button{
    if(self.buttons==nil){
        self.buttons = [NSMutableArray array];
    }
    if (button) {
        [self.buttons addObject:button];
        [button addTarget:self action:@selector(buttonPush:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)compile{
    
    UITapGestureRecognizer *tapBack = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(close:)];
    [self.backview addGestureRecognizer:tapBack];
    
    self.maxHeight = ceilf(2*(self.frame.size.height/3));
    for(CastButton *b in self.scrollView.subviews){
        [b removeFromSuperview];
    }
    CGFloat height = 0;
    CGFloat totalHeight = 0;
    for(CastButton *b in self.buttons){
        b.frame = CGRectMake(0,totalHeight,self.scrollView.frame.size.width,b.frame.size.height);
        [b compile];
        [self.scrollView addSubview:b];
        height = b.frame.size.height + MARGIN;
        totalHeight += height;
        NSLog(@"adding button for device:%@ height:%f", b.mainTitle, height);
    }
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width,totalHeight);
    NSLog(@"scrollView contentsize:(%fx%f) number of subviews:%lu", self.scrollView.frame.size.width,totalHeight, (unsigned long)self.scrollView.subviews.count);
    
    CGFloat dialogHeight = self.title.frame.origin.y + self.title.frame.size.height + MARGIN_BETWEEN_ELEMENTS + totalHeight + MARGIN_BETWEEN_ELEMENTS + self.closeButton.frame.size.height +MARGIN_BETWEEN_ELEMENTS+MARGIN;
    CGFloat containerHeight = dialogHeight;
    if(dialogHeight>self.maxHeight){
        containerHeight = self.maxHeight;
    }
    self.containerView.frame = CGRectMake(self.containerView.frame.origin.x,
                                          ceilf((self.frame.size.height-containerHeight)/2),
                                          self.containerView.frame.size.width,
                                          containerHeight);
    [self.containerView setNeedsLayout];
    
}


- (void)buttonPush:(CastButton *)sender{
    if(sender && self.delegate){
        int index = (int)[self.buttons indexOfObject:sender];
        [self.delegate castDeviceSelectionViewDidSelectIndex:index];
    }
}


- (IBAction)close:(id)sender {
    if(self.delegate){
        [self.delegate castDeviceSelectionViewDidCancel];
    }
}


- (void)dealloc {
    [_scrollView release];
    [_backview release];
    [_title release];
    [_closeButton release];
    [_containerView release];
    [super dealloc];
}
@end
