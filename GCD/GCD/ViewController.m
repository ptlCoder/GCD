//
//  ViewController.m
//  GCD
//
//  Created by soliloquy on 2017/8/10.
//  Copyright © 2017年 soliloquy. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self gcdDemo9];
}

// GCD的队列组 dispatch_group
- (void)gcdDemo9 {
    /*
        "3"会等待前面的"1""2"打印完才会打印, "1""2"异步操作会交替打印
     */
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 执行1个耗时的异步操作
        
        for (NSInteger i = 0; i < 10; i ++) {
            NSLog(@"1----%zd---%@",i, [NSThread currentThread]);
        }
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 执行1个耗时的异步操作
        for (NSInteger i = 0; i < 10; i ++) {
            NSLog(@"2----%zd---%@",i, [NSThread currentThread]);
        }
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 等前面的异步操作都执行完毕后，回到主线程...
        for (NSInteger i = 0; i < 10; i ++) {
            NSLog(@"3----%zd---%@",i, [NSThread currentThread]);
        }
    });

}

//GCD的快速迭代方法 dispatch_apply
- (void)gcdDemo8 {

    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    /**
     同时遍历6次 不按顺序输出
     @param iterations 遍历的次数
     @param queue 在哪个队列
     @param size_t index下标号
     */
    dispatch_apply(6, q, ^(size_t index) {
        NSLog(@"%zd----%@", index, [NSThread currentThread]);
    });
}

//GCD的栅栏方法
- (void)gcdDemo7 {
/*
 ````dispatch_barrier_async
    有时需要异步执行两组操作，而且第一组操作执行完之后，才能开始执行第二组操作。这样我们就需要一个相当于栅栏一样的一个方法将两组异步执行的操作组给分割起来，操作组里可以包含一个或多个任务。这就需要用到dispatch_barrier_async方法在两个操作组间形成栅栏。
 */
    
    /*
        "1"和"2"处于子线程会随机打印顺序 然后打印栅栏"3" 最后打印"4"
     */
    
   dispatch_queue_t q = dispatch_queue_create("ptl", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(q, ^{
        NSLog(@"----1-----%@", [NSThread currentThread]);
    });
    
    dispatch_async(q, ^{
        NSLog(@"----2-----%@", [NSThread currentThread]);
    });
    
    dispatch_barrier_async(q, ^{
        for (NSInteger i = 0; i < 10; i ++) {
//            // 加入到异步后 下面的"4"可能在for之前打印, 可能在中间打印, 也可能在for后面打印
//            dispatch_async(q, ^{
//                NSLog(@"----3 barrier-----%@", [NSThread currentThread]);
//            });
            
            NSLog(@"----3 barrier-----%@", [NSThread currentThread]);
        }
    });
    
    dispatch_async(q, ^{
        NSLog(@"----4-----%@", [NSThread currentThread]);
    });
    
    
}
// 主队列 + 异步执行
- (void)gcdDemo6 {
    /*
        先执行"嘿嘿"->"哈哈"->for里面 for里面的任务会在主队列执行 添加到主队列后不会立马就执行的 会等待一会 所以"哈哈"在for之前就执行了 因为它本身就在主线程中无需等待
     */
    NSLog(@"嘿嘿-----------");
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSInteger i = 0; i < 10; i ++) {
            NSLog(@"😆(%zd)--%@", i, [NSThread currentThread]);
        }
    });
    
    NSLog(@"哈哈-----------");
}
// 主队列 + 同步执行
- (void)gcdDemo5 {
    
    /*
        "嘿嘿"等待for的任务执行完往下执行 而for又等待"嘿嘿"执行完往下执行 所以互相等待 程序卡死 崩溃
     */
    NSLog(@"嘿嘿-----------");
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (NSInteger i = 0; i < 10; i ++) {
            NSLog(@"😆(%zd)--%@", i, [NSThread currentThread]);
        }
    });
    
    NSLog(@"哈哈-----------");
}
// 串行队列 + 异步执行
- (void)gcdDemo4 {
    
    /*
        先执行"嘿嘿", 后面的会随机执行, "哈哈"可能会插入到for中打印
        for是在串行异步执行 所以子线程会执行完当前任务后才会执行下次任务
     */
    
    NSLog(@"嘿嘿-----------");
    dispatch_queue_t q = dispatch_queue_create("ptl", DISPATCH_QUEUE_SERIAL);
    dispatch_async(q, ^{
        for (NSInteger i = 0; i < 2; i ++) {
            dispatch_async(q, ^{
                NSLog(@"😆(%zd)--%@", i, [NSThread currentThread]);
            });
        }
    });
    NSLog(@"哈哈-----------");
    
}
// 串行队列 + 同步执行
- (void)gcdDemo3 {
    
    /*
     DISPATCH_QUEUE_SERIAL : 串行
     按照顺序执行
     */
    NSLog(@"嘿嘿-----------");
    dispatch_queue_t q = dispatch_queue_create("ptl", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(q, ^{
        for (NSInteger i = 0; i < 10; i ++) {
            dispatch_async(q, ^{
                NSLog(@"😆(%zd)--%@", i, [NSThread currentThread]);
            });
        }
    });
    NSLog(@"哈哈-----------");
}

// 并行队列 + 异步执行
- (void)gcdDemo2 {
    /*
     先执行"嘿嘿", 下面的代码都是随机执行 "哈哈"可能在for前,后或者中间打印
     
     */
    NSLog(@"嘿嘿-----------");
    
    dispatch_queue_t q = dispatch_queue_create("ptl", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(q, ^{
        for (NSInteger i = 0; i < 10; i ++) {
            dispatch_async(q, ^{
                NSLog(@"😆(%zd)--%@", i, [NSThread currentThread]);
            });
        }
    });
    NSLog(@"哈哈-----------");
}

// 并行队列 + 同步执行
- (void)gcdDemo1 {
    /* 
        DISPATCH_QUEUE_CONCURRENT 并发
        DISPATCH_QUEUE_SERIAL 串行
     */
    
    NSLog(@"嘿嘿-----------");
    dispatch_queue_t q = dispatch_queue_create("ptl", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(q, ^{
        for (NSInteger i = 0; i < 10; i ++) {
            // 任务在并发子线程执行 所以下面的"哈哈" 可能在for之前 也可能之后
            dispatch_async(q, ^{
                NSLog(@"😆(%zd)--%@", i, [NSThread currentThread]);
            });
        }
    });
    
    NSLog(@"哈哈-----------");
}





@end
