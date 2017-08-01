//
//  WXTabBarController.m
//  仿美团tabbar
//
//  Created by 啷个哩个啷 on 2017/8/1.
//  Copyright © 2017年 new moon. All rights reserved.
//

#import "WXTabBarController.h"

@interface WXTabBarController () <UITabBarControllerDelegate,CAAnimationDelegate>

/**所有的子控件*/
@property (nonatomic, strong) NSMutableArray *subviewsArr;
/***/
@property (nonatomic, strong) CAShapeLayer *circleLayer;
/**动画后*/
@property (nonatomic, strong) UIView *selectImage;
@property (nonatomic, strong) UIImageView *nomalImage;
@property (nonatomic, assign) CGFloat bigDiameter;
/**未选中的图片数组*/
@property (nonatomic, strong) NSArray *nomalImages;
/**当前选中的index*/
@property (nonatomic, assign) NSInteger currentIndex;

@end

@implementation WXTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - 搭建UI
- (void)setupUI{

    [self addChildViewClassName:@"WXOneViewController" withTitle:@"首页" imageName:@"homepage_nomal_iphone" selectedImageName:@"homepage_selected_iphone"];
    [self addChildViewClassName:@"WXTwoViewController" withTitle:@"患者" imageName:@"prescribe_nomal_iphone" selectedImageName:@"prescribe_selected_iphone"];
    [self addChildViewClassName:@"WXThreeViewController" withTitle:@"统计" imageName:@"statistics_nomal_iphone" selectedImageName:@"statistics_selected_iphone"];
    [self addChildViewClassName:@"WXFourViewController" withTitle:@"我的" imageName:@"main_nomal_iphone"
        selectedImageName:@"main_selected_iphone"];
    
    //这里需要设置代理
    self.delegate = self;
}

#pragma mark - 添加子控制器
- (void)addChildViewClassName:(NSString *)ClassName
                    withTitle:(NSString *)title
                    imageName:(NSString *)imageName
            selectedImageName:(NSString *)selectedImageName
{
    UIViewController *childVC = (UIViewController *)[[NSClassFromString(ClassName) alloc] init];
    UINavigationController *naVC = [[UINavigationController alloc] initWithRootViewController:childVC];
    naVC.tabBarItem.title = title;
    naVC.tabBarItem.image  = [UIImage imageNamed:imageName];
    naVC.tabBarItem.selectedImage = [[UIImage imageNamed:selectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    childVC.title = title;
    [self addChildViewController:naVC];
}

#pragma mark - UITabBarControllerDelegate 点击事件
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    
    NSInteger index = [self.childViewControllers indexOfObject:viewController];
    
    if (!self.subviewsArr.count) {
        //拿到所有的item
        for (UIView *btn in self.tabBar.subviews) {
            if ([btn isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
                [self.subviewsArr addObject:btn];
            }
        }
    }
    
    if (self.currentIndex == index) return;
    
    UIView *currentView = [self.subviewsArr objectAtIndex:index]; //拿到当前点击的item
    
    for (UIView *imageView in currentView.subviews) {
        if ([imageView isKindOfClass:NSClassFromString(@"UITabBarSwappableImageView")]) { //拿到istem上的图片视图
            [self setFillAnimationWithView:imageView index:index];
//            [self setScaleAnimationWithView:imageView];
        }
    }
    
    self.currentIndex = index;
    
}

#pragma mark -- animation
/**放大弹跳效果**/
- (void)setScaleAnimationWithView:(UIView *)imageView{
    
    // 需要实现的帧动画,这里根据需求自定义
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    animation.values = @[@1.0,@1.3,@0.9,@1.15,@0.95,@1.02,@1.0];
    animation.duration = 1;
    animation.calculationMode = kCAAnimationCubic;
    // 把动画添加到对应控件的layer上去就OK了
    [imageView.layer addAnimation:animation forKey:nil];
    
}

/**填充效果**/
- (void)setFillAnimationWithView:(UIView *)imageView index:(NSInteger)index{
    
    [_nomalImage removeFromSuperview];
    self.selectImage = imageView;
    
    _nomalImage = [[UIImageView alloc]initWithImage:[UIImage imageNamed:self.nomalImages[index]]];
    _nomalImage.center = imageView.center;
    [imageView.superview addSubview:_nomalImage];
    
    //平方根函数  获取直径
    self.bigDiameter = sqrt(CGRectGetWidth(_nomalImage.bounds)*CGRectGetWidth(_nomalImage.bounds) + CGRectGetHeight(_nomalImage.bounds) *CGRectGetHeight(_nomalImage.bounds));
    [_nomalImage.layer addSublayer:self.circleLayer];
    
    [self reveal];
}
#pragma mark - CAAnimationDelegate
/**
 *  根据直径生成圆的path，注意圆点是self的中心点，所以（x，y）不是（0，0）
 */
- (UIBezierPath *)pathWithDiameter:(CGFloat)diameter {
    //创建圆
    return [UIBezierPath bezierPathWithOvalInRect:CGRectMake((CGRectGetWidth(self.selectImage.bounds) - diameter) / 2, (CGRectGetHeight(self.selectImage.bounds) - diameter) / 2, diameter, diameter)];
}

- (void)reveal {
    
    [self.circleLayer removeFromSuperlayer];//理论上作为mask的layer不能有父layer，所以要remove掉
    self.selectImage.layer.mask = self.circleLayer;
    _selectImage.hidden = NO;
    //让圆的变大的动画
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    UIBezierPath *toPath = [self pathWithDiameter:self.bigDiameter];
    //    UIBezierPath *toPath = [self pathWithDiameter:0];//缩小当前path的动画
    pathAnimation.toValue = (id)toPath.CGPath;
    pathAnimation.duration = 0.5;
    
    //让圆的线的宽度变大的动画，效果是内圆变小
    CABasicAnimation *lineWidthAnimation = [CABasicAnimation animationWithKeyPath:NSStringFromSelector(@selector(lineWidth))];
    lineWidthAnimation.toValue = @(self.bigDiameter);
    lineWidthAnimation.duration = 0.5;
    
    //组动画
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[pathAnimation, lineWidthAnimation];
    group.duration =  0.5;
    group.removedOnCompletion = NO;//这两句的效果是让动画结束后不会回到原处，必须加
    group.fillMode = kCAFillModeForwards;//这两句的效果是让动画结束后不会回到原处，必须加
    group.delegate = self;
    
    [self.circleLayer addAnimation:group forKey:@"revealAnimation"];
    
    [UIView animateWithDuration:0.5f animations:^{
        self.nomalImage.alpha = 0;
    }];
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    
}
#pragma mark -- lazy
- (NSMutableArray *)subviewsArr{
    if (!_subviewsArr) {
        _subviewsArr = [NSMutableArray array];
    }
    
    return _subviewsArr;
}

- (NSArray *)nomalImages{
    if (!_nomalImages) {
        _nomalImages = @[@"homepage_nomal_iphone",@"prescribe_nomal_iphone",@"statistics_nomal_iphone",@"main_nomal_iphone"];
    }
    
    return _nomalImages;
}

- (CAShapeLayer *)circleLayer {
    if (!_circleLayer) {
        _circleLayer = [CAShapeLayer layer];
        _circleLayer.fillColor = [UIColor clearColor].CGColor;//这个必须透明，因为这样内圆才是不透明的
        _circleLayer.strokeColor = [UIColor whiteColor].CGColor;//注意这个必须不能透明，因为实际上是这个显示出后面的图片了
        _circleLayer.path = [self pathWithDiameter:0.00001].CGPath;
    }
    return _circleLayer;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
