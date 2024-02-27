/*
 * DemoViewController.m
 *
 * Copyright (c) 2015-2024 The Brenwill Workshop Ltd. (http://www.brenwill.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "DemoViewController.h"

#include <MoltenVK/mvk_vulkan.h>
#include "cube.c"


#pragma mark -
#pragma mark DemoViewController

@implementation DemoViewController {
	CADisplayLink* _displayLink;
	struct demo demo;
    UIWindow* externalWindow;
    Boolean shouldRend;
}
- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    NSLog(@"initWithCoder");
    [self initLog];
    shouldRend = false;
    return [super initWithCoder:coder];
}
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
    NSLog(@"initWithNibName");
    [self initLog];
    
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

-(void) initLog{
    NSString *logText = [NSString stringWithFormat:@"[%@] This is a log message.\n", [self currentTime]];
    LogToFileWriter* writer = [[LogToFileWriter alloc] init];
    [writer writeLog:logText];
}

-(NSString*) currentTime{
    // 获取当前时间
    NSDate *currentDate = [NSDate date];

    // 创建日期格式化器
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    // 将当前时间格式化为字符串
    NSString *formattedDateString = [dateFormatter stringFromDate:currentDate];
    return formattedDateString;
}

//-(void) screenConnected:(NSNotification *)notification{
-(void) screenConnected{
//    UIScreen *newScreen = notification.object;
    NSString *logText = [NSString stringWithFormat:@"[%@] screenConnected.\n", [self currentTime]];
    LogToFileWriter* writer = [[LogToFileWriter alloc] init];
    [writer writeLog:logText];
    
    NSArray<UIScreen *> *screens = [UIScreen screens];
    for(UIScreen* screen in screens){
        NSString *logMessage = [NSString stringWithFormat:@"[%@]screenConnected screenCount: %lu, Find Screen %p dimensions: %@, scale: %f, mirrored: %p\n", [self currentTime], (unsigned long)[[UIScreen screens] count], screen, NSStringFromCGRect(screen.bounds), screen.scale, screen.mirroredScreen];
        [writer writeLog:logMessage];
        NSLog(@"screenConnected screenCount: %lu, Find Screen %p dimensions: %@, scale: %f, mirrored: %p", (unsigned long)[[UIScreen screens] count], screen, NSStringFromCGRect(screen.bounds), screen.scale, screen.mirroredScreen);
    }
    
    if([screens count] > 1){
        UIScreen* screen = screens[1];
        CGRect screenBounds = screen.bounds;
//        screenBounds.size.width /= 2;
//        screenBounds.size.height /= 2;

        externalWindow = [[UIWindow alloc] initWithFrame:screenBounds];
        externalWindow.screen = screen;

        // 创建您的视图控制器并添加到窗口
        GlassViewController *viewController = [[GlassViewController alloc] init];
        viewController.view.backgroundColor = [UIColor orangeColor]; // 示例背景色
        UIView* view = viewController.view;
        externalWindow.rootViewController = viewController;

        // 显示窗口
        [externalWindow makeKeyAndVisible];
        
        [self initRender:view];
    }
}

-(void) screenDisconnected{
    NSString *logText = [NSString stringWithFormat:@"[%@] screenDisconnected.\n", [self currentTime]];
    LogToFileWriter* writer = [[LogToFileWriter alloc] init];
    [writer writeLog:logText];
    [self initRender:NULL];
}

-(void) viewDidLoad {
    [super viewDidLoad];
    // 设置视图的背景色为红色
    self.view.backgroundColor = [UIColor redColor];
    // 注册 UIScreen 连接状态变化的通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenConnected)
                                                 name:UIScreenDidConnectNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenDisconnected)
                                                 name:UIScreenDidDisconnectNotification
                                               object:nil];
    // 检查是否有外接显示器
    NSArray *connectedScreens = [UIScreen screens];
    
    NSString *logText = [NSString stringWithFormat:@"[%@] ViewDidLoad. screenCount: %lu\n", [self currentTime], (unsigned long)[connectedScreens count]];
    NSLog(@"%@", logText);
    LogToFileWriter* writer = [[LogToFileWriter alloc] init];
    [writer writeLog:logText];
}

/** Since this is a single-view app, initialize Vulkan as view is appearing. */
-(void) viewWillAppear: (BOOL) animated {
	[super viewWillAppear: animated];

	self.view.contentScaleFactor = UIScreen.mainScreen.nativeScale;

#if TARGET_OS_SIMULATOR
	// Avoid linear host-coherent texture loading on simulator
	const char* argv[] = { "cube", "--use_staging" };
#else
	const char* argv[] = { "cube" };
#endif
    UIView* view = NULL;
    LogToFileWriter* writer = [[LogToFileWriter alloc] init];
    NSArray<UIScreen *> *screens;
//    do {
//        sleep(1);
        screens = [UIScreen screens];
        for(UIScreen* screen in screens){
            NSString *logMessage = [NSString stringWithFormat:@"[%@]screenCount: %lu, Find Screen %p dimensions: %@, scale: %f, mirrored: %p\n", [self currentTime], (unsigned long)[[UIScreen screens] count], screen, NSStringFromCGRect(screen.bounds), screen.scale, screen.mirroredScreen];
            [writer writeLog:logMessage];
            NSLog(@"screenCount: %lu, Find Screen %p dimensions: %@, scale: %f, mirrored: %p", (unsigned long)[[UIScreen screens] count], screen, NSStringFromCGRect(screen.bounds), screen.scale, screen.mirroredScreen);
        }
//    } while ([screens count] == 1);
    
    
    
    for (UISceneSession *session in UIApplication.sharedApplication.openSessions) {
        UIScene *scene = session.scene;
        NSString* logRole = [NSString stringWithFormat:@"session role: %@", session.role];
        NSLog(@"%@", logRole);
        [writer writeLog:logRole];
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            UIScreen *screen = windowScene.screen;
            NSString *logMessage = [NSString stringWithFormat:@"session find screen: %p\n", screen];
            [writer writeLog:logMessage];
            
            // 检查是否为主屏幕
            if (screen != UIScreen.mainScreen) {
                NSLog(@"Found an external screen.");
                
                // 在这里处理外部屏幕
                NSLog(@"Screen dimensions: %@, scale: %f", NSStringFromCGRect(screen.bounds), screen.scale);
                
//                CGRect screenBounds = screen.bounds;
//                screenBounds.size.width /= 2;
//                screenBounds.size.height /= 2;
//
//                externalWindow = [[UIWindow alloc] initWithFrame:screenBounds];
//                externalWindow.screen = screen;
//
//                // 创建您的视图控制器并添加到窗口
//                GlassViewController *viewController = [[GlassViewController alloc] init];
//                viewController.view.backgroundColor = [UIColor orangeColor]; // 示例背景色
//                view = viewController.view;
//                externalWindow.rootViewController = viewController;
//
//                // 显示窗口
//                [externalWindow makeKeyAndVisible];
//                break;
                
            }
            else {
                NSLog(@"Found an main screen.");
                
                // 在这里处理主屏幕
                NSLog(@"Screen dimensions: %@, scale: %f", NSStringFromCGRect(screen.bounds), screen.scale);
                NSLog(@"Screen cordSpace: %@, size: %@", screen.coordinateSpace, NSStringFromCGSize(screen.currentMode.size));
                
//                CGRect screenBounds = screen.bounds;
//                screenBounds.size.width /= 2;
//                screenBounds.size.height /= 3;
//
//                externalWindow = [[UIWindow alloc] initWithFrame:screenBounds];
//                externalWindow.screen = screen;
//
//                // 创建您的视图控制器并添加到窗口
//                GlassViewController *viewController = [[GlassViewController alloc] init];
//                viewController.view.backgroundColor = [UIColor orangeColor]; // 示例背景色
//                view = viewController.view;
//                externalWindow.rootViewController = viewController;
//
//                // 显示窗口
//                [externalWindow makeKeyAndVisible];
                
            }
        }
    }
    [self initRender:NULL];
}

-(void) initRender:(UIView*) view {
#if TARGET_OS_SIMULATOR
    // Avoid linear host-coherent texture loading on simulator
    const char* argv[] = { "cube", "--use_staging" };
#else
    const char* argv[] = { "cube" };
#endif
    
    int argc = sizeof(argv)/sizeof(char*);
    
    if(shouldRend){
        shouldRend = false;
        demo_cleanup(&demo);
    }
    
    if(view == NULL) {
        demo_main(&demo, self.view.layer, argc, argv);
    }
    else {
        demo_main(&demo, view.layer, argc, argv);
    }
    demo_draw(&demo);
    shouldRend = true;
    uint32_t fps = 60;
    _displayLink = [CADisplayLink displayLinkWithTarget: self selector: @selector(renderLoop)];
    [_displayLink setFrameInterval: 60 / fps];
    [_displayLink addToRunLoop: NSRunLoop.currentRunLoop forMode: NSDefaultRunLoopMode];
}

-(void) renderLoop {
    if(shouldRend){
        demo_draw(&demo);
    }
    // 检查是否有外接显示器
//    NSArray *connectedScreens = [UIScreen screens];
//    NSLog(@"renderLoop screen count: %lu", [connectedScreens count]);
}

// Allow device rotation to resize the swapchain
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	demo_resize(&demo);
}

-(void) viewDidDisappear: (BOOL) animated {
	[_displayLink invalidate];
	[_displayLink release];
	demo_cleanup(&demo);
	[super viewDidDisappear: animated];
}

@end


#pragma mark -
#pragma mark GlassViewController

@implementation GlassViewController

-(void) loadView {
    self.view = [[DemoView alloc] init];
}

@end


#pragma mark -
#pragma mark DemoView

@implementation DemoView

/** Returns a Metal-compatible layer. */
+(Class) layerClass { return [CAMetalLayer class]; }

@end


#pragma mark -
#pragma mark LogToFileWriter

@implementation LogToFileWriter {
    // 获取应用容器的Documents目录路径
    NSArray *paths;
    NSString *documentsDirectory;

    // 创建要保存的文件路径
    NSString *filePath;

    // 创建 NSOutputStream 对象
    NSOutputStream *_outputStream;
}

-(id) init{
    self = [super init];
    [self beginLog];
    return self;
}

-(void) beginLog{
    // 获取应用容器的Documents目录路径
    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];

    // 创建要保存的文件路径
    filePath = [documentsDirectory stringByAppendingPathComponent:@"app_log.txt"];

    // 创建 NSOutputStream 对象
    _outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:YES];
    [_outputStream open];
}

-(void) writeLog:(NSString*) logText {
    NSData *logData = [logText dataUsingEncoding:NSUTF8StringEncoding];
    // 写入日志数据到文件流
    [_outputStream write:[logData bytes] maxLength:[logData length]];
}

-(void) dealloc{
    NSLog(@"LogToFileWriter dealloc...");
    [super dealloc];
    [_outputStream close];
}

@end
