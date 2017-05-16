//
//  TextParser.m
//  WeiboTextParserDemo
//
//  Created by wanghong on 2017/5/16.
//  Copyright © 2017年 lucifron. All rights reserved.
//

#import "TextParser.h"
#import "YYText.h"

#define kNormalFontSize 18


@interface TextParser (){
    
    NSRegularExpression *_regexAt;
    NSRegularExpression *_regexPoundSign;
    
    NSRegularExpression *_regexImage;
    NSDictionary *_imageMapper;
    
    UIFont *_normalFont;
    UIColor *_normalColor;
    UIColor *_atTextColor;
}

@end

@implementation TextParser

- (instancetype)init{
    self = [super init];
    if (self) {
        [self initFont];
        
        [self initRegex];
        
        [self initMapper];
        
    }
    return self;
}

- (void)initFont{
    _normalFont = [UIFont systemFontOfSize:kNormalFontSize];
    _normalColor = [UIColor darkGrayColor];
    _atTextColor = [UIColor orangeColor];
}

- (void)initRegex{
#define regexp(reg, option) [NSRegularExpression regularExpressionWithPattern : @reg options : option error : NULL]
    _regexAt = regexp("@[\u4e00-\u9fa5a-zA-Z0-9_-]{2,30}", 0);
    _regexPoundSign = regexp("#[^#]+#", 0);
#undef regexp
}


- (void)initMapper{
    _imageMapper = @{
                     @"[嘻嘻]" : [UIImage imageNamed:@"yb001"],
                     @"[呆]" : [UIImage imageNamed:@"yb002"],
                     @"[色]" : [UIImage imageNamed:@"yb003"]
                     
                     };
    
    
    NSMutableString *pattern = @"(".mutableCopy;
    NSArray *allKeys = _imageMapper.allKeys;
    NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@"$^?+*.,#|{}[]()\\"];
    for (NSUInteger i = 0, max = allKeys.count; i < max; i++) {
        NSMutableString *one = [allKeys[i] mutableCopy];
        
        // escape regex characters
        for (NSUInteger ci = 0, cmax = one.length; ci < cmax; ci++) {
            unichar c = [one characterAtIndex:ci];
            if ([charset characterIsMember:c]) {
                [one insertString:@"\\" atIndex:ci];
                ci++;
                cmax++;
            }
        }
        
        [pattern appendString:one];
        if (i != max - 1) [pattern appendString:@"|"];
    }
    [pattern appendString:@")"];
    _regexImage = [[NSRegularExpression alloc] initWithPattern:pattern options:kNilOptions error:nil];
    
}


#pragma mark - YYTextParser

- (BOOL)parseText:(NSMutableAttributedString *)text selectedRange:(NSRangePointer)range {
    __block BOOL changed = NO;
    
    if (text.length == 0) { return NO; }
    
    text.yy_font = _normalFont;
    text.yy_color = _normalColor;
    
    // @用户
    [_regexAt enumerateMatchesInString:text.string options:NSMatchingWithoutAnchoringBounds range:text.yy_rangeOfAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        NSRange range = result.range;
        [text yy_setColor:_atTextColor range:range];
        changed = YES;
    }];
    
    
    // #话题#
    [_regexPoundSign enumerateMatchesInString:text.string options:NSMatchingWithoutAnchoringBounds range:text.yy_rangeOfAll usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        
        NSRange range = result.range;
        [text yy_setColor:_atTextColor range:range];
        changed = YES;
    }];
    
    // 图片
    
    if (_imageMapper.count){
        NSArray *matches = [_regexImage matchesInString:text.string options:kNilOptions range:NSMakeRange(0, text.length)];
        
        if (matches.count) {
            NSRange selectedRange = range ? *range : NSMakeRange(0, 0);
            NSUInteger cutLength = 0;
            for (NSUInteger i = 0, max = matches.count; i < max; i++) {
                NSTextCheckingResult *one = matches[i];
                NSRange oneRange = one.range;
                if (oneRange.length == 0) continue;
                oneRange.location -= cutLength;
                NSString *subStr = [text.string substringWithRange:oneRange];
                UIImage *emoticon = _imageMapper[subStr];
                if (!emoticon) continue;
                
                CGFloat fontSize = kNormalFontSize;
                CTFontRef font = (__bridge CTFontRef)([text yy_attribute:NSFontAttributeName atIndex:oneRange.location]);
                if (font) fontSize = CTFontGetSize(font);
                
                NSMutableAttributedString *atr = [NSAttributedString yy_attachmentStringWithEmojiImage:emoticon fontSize:fontSize];
                
                //                    NSMutableAttributedString *atr = [NSAttributedString yy_attachmentStringWithContent:emoticon contentMode:UIViewContentModeCenter attachmentSize:emoticon.size alignToFont:_normalFont alignment:YYTextVerticalAlignmentCenter];
                
                [atr yy_setTextBackedString:[YYTextBackedString stringWithString:subStr] range:NSMakeRange(0, atr.length)];
                [text replaceCharactersInRange:oneRange withString:atr.string];
                [text yy_removeDiscontinuousAttributesInRange:NSMakeRange(oneRange.location, atr.length)];
                [text addAttributes:atr.yy_attributes range:NSMakeRange(oneRange.location, atr.length)];
                selectedRange = [self _replaceTextInRange:oneRange withLength:atr.length selectedRange:selectedRange];
                cutLength += oneRange.length - 1;
            }
            if (range) *range = selectedRange;
            
            changed = YES;
        }
        
    }
    
    
    return changed;
}

#pragma mark - Helper

// correct the selected range during text replacement
- (NSRange)_replaceTextInRange:(NSRange)range withLength:(NSUInteger)length selectedRange:(NSRange)selectedRange {
    // no change
    if (range.length == length) return selectedRange;
    // right
    if (range.location >= selectedRange.location + selectedRange.length) return selectedRange;
    // left
    if (selectedRange.location >= range.location + range.length) {
        selectedRange.location = selectedRange.location + length - range.length;
        return selectedRange;
    }
    // same
    if (NSEqualRanges(range, selectedRange)) {
        selectedRange.length = length;
        return selectedRange;
    }
    // one edge same
    if ((range.location == selectedRange.location && range.length < selectedRange.length) ||
        (range.location + range.length == selectedRange.location + selectedRange.length && range.length < selectedRange.length)) {
        selectedRange.length = selectedRange.length + length - range.length;
        return selectedRange;
    }
    selectedRange.location = range.location + length;
    selectedRange.length = 0;
    return selectedRange;
}

@end
