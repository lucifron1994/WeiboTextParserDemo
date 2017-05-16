//
//  ViewController.m
//  WeiboTextParserDemo
//
//  Created by wanghong on 2017/5/16.
//  Copyright © 2017年 lucifron. All rights reserved.
//

#import "ViewController.h"
#import "YYText.h"
#import "TextParser.h"


@interface ViewController ()

@property (strong, nonatomic) YYTextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    self.textView = [[YYTextView alloc]init];
    self.textView.frame = self.view.bounds;
    self.textView.tintColor = [UIColor orangeColor];
    self.textView.textParser = [[TextParser alloc]init];
    [self.view addSubview:self.textView];
    
    [self initText];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.textView becomeFirstResponder];
}

- (void)initText{
    NSString *text = @"//At:@lucifron_ Topic:#热门话题#  Emoji:[嘻嘻][呆][色][嘻嘻][呆][色] \n 输入: [ + 呆 + ] = [呆]\n";
    self.textView.text = text;
}

- (IBAction)refresh:(id)sender {
    [self initText];
}


@end
