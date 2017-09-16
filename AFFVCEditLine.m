//
//  AFFVCEditLine.m
//  AnyfishApp
//
//  Created by Bob Lee on 15/11/6.
//  Copyright © 2015年 Anyfish. All rights reserved.
//

#import "AFFVCEditLine.h"

typedef void(^lineBlock)(BOOL isCancel, NSString *text);

@interface AFFVCEditLine ()<UITextFieldDelegate> {
    lineBlock lblock;
    void(^backBlock)(BOOL isBack, NSString *text);
}
@property (nonatomic, weak)   UITextField          *textField;        ///<
@property (nonatomic, weak)   UILabel              *labLimit;        ///<显示字数lab
@end

@implementation AFFVCEditLine

#pragma mark  初始化
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationItem setItemWithTarget:self isLeft:NO action:@selector(clickRightNavItem) title:kAFLocalize(kActConfirm) imageNor:nil];
    [self.navigationItem setNewTitle:self.navTitle];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(textFiledEditChanged:)
                                                name:UITextFieldTextDidChangeNotification object:self.textField];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(someMethod:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    [self setup];
    [self setupData];
}

- (void)setup{
    CGRect frame = self.view.bounds;
    
    frame.size.height = 44;
    frame.origin.y = kNavigationBar_Height + kStatusBar_Height + kMargin_Cell_V;
    UIView *view = [[UIView alloc]initWithFrame:frame];
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];
    
    frame.size.height = kSetting.font_Content.lineHeightUsed;
    frame.size.width = SCREEN_WIDTH - kMargin_Cell_Item_H;
    frame.origin.x = kMargin_Cell_Item_H;
    frame.origin.y = (CGRectGetHeight(view.frame) - frame.size.height)/2;
    
    UITextField *textFiled = [[UITextField alloc]initWithFrame:frame];
    textFiled.font = kSetting.font_Content;
    textFiled.textColor = kSetting.color_Content;
    textFiled.keyboardType = self.keyboardType?self.keyboardType:UIKeyboardTypeDefault;
    textFiled.clearButtonMode = UITextFieldViewModeWhileEditing;
    textFiled.returnKeyType = UIReturnKeyDone;
    textFiled.delegate = self;
    [textFiled becomeFirstResponder];
    [view addSubview:textFiled];
    self.textField = textFiled;
    
    frame.size.width = 100;
    frame.size.height = kSetting.font_Content.lineHeightUsed;
    frame.origin.y = CGRectGetMaxY(view.frame) + 8;
    frame.origin.x = SCREEN_WIDTH - frame.size.width - kMargin_Cell_H;
    UILabel *labLimit = [[UILabel alloc]initWithFrame:frame];
    labLimit.font = kSetting.font_Content;
    labLimit.textColor = kSetting.color_Content;
    labLimit.textAlignment = kTextAlignmentRight;
    [self.view addSubview:labLimit];
    self.labLimit = labLimit;
    
}

- (void)handleConfirm:(void (^)(BOOL, NSString *))block {
    lblock = block;
}

- (void)handleBack:(void (^)(BOOL, NSString *))block{
    backBlock = block;
}

- (void)setupData{
    self.textField.text = self.text;
    [self setLablimitlength:(int)self.text.length];
    if (self.maxCharacter) {
        self.labLimit.hidden = YES;
    }
}

#pragma mark 根据类型解析各种判断标识

- (void)setEditType:(EEditlineType)editType{
    switch (editType) {
        case EEditlinePlayerNick:
        {
            self.navTitle = @"个人昵称";
            self.maxCharacter = 16;
            self.placeholder =  @"请输个人昵称";
            self.hudText = @"个人昵称字数不能超过8个字符";
            
        }
            break;
        case EEditlineRoomName:
        {
            self.navTitle = @"设置群名称";
            self.maxCharacter = 10;
            self.placeholder =  @"请输入群名称";
            self.hudText = @"群名称字数不能超过10个字符";
        }
            break;
        case EEditlineRoomNick:
        {
            self.navTitle = @"设置群昵称";
            self.maxCharacter = 8;
            self.placeholder =  @"请输入群昵称";
            self.hudText = @"群昵称字数不能超过8个字符";
        }
            break;
        case EEditlineBillDesk:
        {
            self.navTitle = @"创建桌号";
            self.maxCharacter = 8;
            self.placeholder =  @"请输入桌号";
            self.hudText = @"桌号字数不能超过8个字符";

        }
            break;
        default:
            break;
    }
    _editType = editType;
}


#pragma mark 输入中检查
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if (self.maxCharacter <= 0) {
        return YES;
    }
    
    //有时键盘需要处理删除符号
    const char *str = [string UTF8String];
    if(*str == 0){
        return YES;
    }
    UITextRange *selectedRange = [textField markedTextRange];
    //获取高亮部分
    UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
    // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
    if (!position) {
        
        NSString *newString = [textField.text stringByAppendingString:string];
        int number = (int)newString.length;
        if (number > self.maxCharacter) {
            [HUD showWithText:self.hudText];
            return NO;
        }
    }
    if([string isEqual:@"\n"]){
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textFiledEditChanged:(NSNotification *)obj{
    UITextField *textField = (UITextField *)obj.object;
    NSString *toBeString = textField.text;
    // 键盘输入模式
    NSString *lang = [[UITextInputMode currentInputMode] primaryLanguage];
    if ([lang isEqualToString:@"zh-Hans"])
    {
        // 简体中文输入，包括简体拼音，健体五笔，简体手写
        UITextRange *selectedRange = [textField markedTextRange];
        //获取高亮部分
        UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
        // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
        if (!position)
        {
            if (toBeString.length > self.maxCharacter)
            {
                textField.text = [toBeString substringToIndex:self.maxCharacter];
                [HUD showWithText:self.hudText];
            }
        }
        // 有高亮选择的字符串，则暂不对文字进行统计和限制
        else
        {
            return;
        }
    }
    // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
    else
    {
        if (toBeString.length > self.maxCharacter)
        {
            textField.text = [toBeString substringToIndex:self.maxCharacter];
        }
    }

    [self setLablimitlength:(int)textField.text.length];

}

- (void)someMethod:(NSNotification *)obj{
    self.textField.text = self.textField.text;
}


- (void)setLablimitlength:(int)length{
    self.labLimit.text = [NSString stringWithFormat:@"%d/%d",length,self.maxCharacter];
}

#pragma mark 用户确认检查
- (void)clickRightNavItem{
    // TODO: 做好各种数据检查，如果某个类型有特殊要求，要单独判断
    if([NSString isNilOrEmpty:self.textField.text]){
        if (!self.isNickName) {
            [HUD showWithText:self.placeholder];
            return;
        }
    }
    
    [self.view endEditing:YES];
    // 检查好了，通知外部处理
    lblock(NO, self.textField.text);
}

- (void)pullBack{
    
    if (backBlock) {
        [self.textField resignFirstResponder];
        [ALERT alertWithTitle:@"是否确定放弃本次编辑" btnTitle:@[@"取消",@"确定"] block:^(NSInteger index, BOOL isCancel) {
            if (index == 0) {
                backBlock(NO,nil);
            }else{
                backBlock(YES,self.textField.text);
                [super pullBack];
            }
            [ALERT dismiss];

        }];
    }else{
        [super pullBack];
    }
    
}

#pragma mark 数据清理
// 不要忘记清理
- (void)cleanSelf {
    if (self.hadCleaned) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.textField = nil;
    self.labLimit = nil;
    lblock = nil;
    backBlock = nil;
    [super cleanSelf];
}

@end
