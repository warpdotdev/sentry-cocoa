#import "SentrySpan.h"
#import "NSDate+SentryExtras.h"
#import "SentryCurrentDate.h"
#import "SentryTraceHeader.h"
#import "SentryTracer.h"

NS_ASSUME_NONNULL_BEGIN

@interface
SentrySpan ()

@property (nonatomic) SentryTracer *tracer;

@end

@implementation SentrySpan {
    NSMutableDictionary<NSString *, id> *_extras;
}

- (instancetype)initWithTracer:(SentryTracer *)tracer context:(SentrySpanContext *)context
{
    if ([self initWithContext:context]) {
        self.tracer = tracer;
    }
    return self;
}

- (instancetype)initWithContext:(SentrySpanContext *)context
{
    if ([super init]) {
        _context = context;
        self.startTimestamp = [SentryCurrentDate date];
        _extras = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id<SentrySpan>)startChildWithOperation:(NSString *)operation
{
    return [self startChildWithOperation:operation description:nil];
}

- (id<SentrySpan>)startChildWithOperation:(NSString *)operation
                              description:(nullable NSString *)description
{
    return [self.tracer startChildWithParentId:[self.context spanId]
                                     operation:operation
                                   description:description];
}

- (void)setDataValue:(nullable NSString *)value forKey:(NSString *)key
{
    @synchronized(_extras) {
        [_extras setValue:value forKey:key];
    }
}

- (nullable NSDictionary<NSString *, id> *)data
{
    @synchronized(_extras) {
        return [_extras copy];
    }
}

- (BOOL)isFinished
{
    return self.timestamp != nil;
}

- (void)finish
{
    self.timestamp = [SentryCurrentDate date];
}

- (void)finishWithStatus:(SentrySpanStatus)status
{
    self.context.status = status;
    [self finish];
}

- (SentryTraceHeader *)toTraceHeader
{
    return [[SentryTraceHeader alloc] initWithTraceId:self.context.traceId
                                               spanId:self.context.spanId
                                              sampled:self.context.sampled];
}

- (NSDictionary *)serialize
{
    NSMutableDictionary<NSString *, id> *mutableDictionary =
        [[NSMutableDictionary alloc] initWithDictionary:[self.context serialize]];

    [mutableDictionary setValue:@(self.timestamp.timeIntervalSince1970) forKey:@"timestamp"];

    [mutableDictionary setValue:@(self.startTimestamp.timeIntervalSince1970)
                         forKey:@"start_timestamp"];

    if (_extras != nil) {
        @synchronized(_extras) {
            [mutableDictionary setValue:_extras.copy forKey:@"data"];
        }
    }

    return mutableDictionary;
}

@end

NS_ASSUME_NONNULL_END
