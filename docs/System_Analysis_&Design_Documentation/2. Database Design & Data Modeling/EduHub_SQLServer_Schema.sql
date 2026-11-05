-- EduHub | proposed SQL Server / Azure SQL physical schema
-- Companion to EduHub Logical & Physical Schema PDF
-- Review with team, run on a NON-PRODUCTION test database after Identity migration.
-- Source: supplied EduHub brief + approved candidate ERD (38 logical entities).
-- Identity tables Users, Roles, UserRoles and four auxiliary tables
-- are created by ASP.NET Core Identity EF Core migrations; not recreated here.
-- Identity string key: nvarchar(450). The user extension fields DisplayName, CreatedAt, IsActive
-- must be configured in the ApplicationUser EF entity and its Identity migration.
SET XACT_ABORT ON;
GO

-- Identity / StudentProfile
CREATE TABLE [dbo].[StudentProfiles] (
    [UserId] nvarchar(450) NOT NULL,
    [Bio] nvarchar(1000) NULL,
    [PreferencesJson] nvarchar(max) NULL,
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_StudentProfiles] PRIMARY KEY ([UserId]),
    CONSTRAINT [FK_StudentProfiles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION
);
GO
GO

-- Identity / InstructorProfile
CREATE TABLE [dbo].[InstructorProfiles] (
    [UserId] nvarchar(450) NOT NULL,
    [Headline] nvarchar(180) NULL,
    [Bio] nvarchar(max) NULL,
    [PayoutAccountRef] nvarchar(180) NULL,
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_InstructorProfiles] PRIMARY KEY ([UserId]),
    CONSTRAINT [FK_InstructorProfiles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION
);
GO
GO

-- Catalog / Category
CREATE TABLE [dbo].[Categories] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [ParentId] bigint NULL,
    [Name] nvarchar(100) NOT NULL,
    [Slug] nvarchar(120) NOT NULL,
    [IsActive] bit NOT NULL DEFAULT (1),
    [SortOrder] int NOT NULL DEFAULT (0),
    CONSTRAINT [PK_Categories] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Categories_Categories_ParentId] FOREIGN KEY ([ParentId]) REFERENCES [dbo].[Categories] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_Categories_01] CHECK ([SortOrder] >= 0)
);
GO
CREATE UNIQUE INDEX [UX_Categories_Slug] ON [dbo].[Categories] ([Slug]);
CREATE INDEX [IX_Categories_ParentId_SortOrder] ON [dbo].[Categories] ([ParentId], [SortOrder]);
GO

-- Catalog / MediaAsset
CREATE TABLE [dbo].[MediaAssets] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [UploadedByUserId] nvarchar(450) NOT NULL,
    [Kind] varchar(20) NOT NULL,
    [BlobKey] nvarchar(500) NOT NULL,
    [ContentType] varchar(120) NOT NULL,
    [SizeBytes] bigint NOT NULL DEFAULT (0),
    [DurationSeconds] int NULL,
    [ProcessingStatus] varchar(20) NOT NULL DEFAULT 'Pending',
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_MediaAssets] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_MediaAssets_Users_UploadedByUserId] FOREIGN KEY ([UploadedByUserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_MediaAssets_01] CHECK ([Kind] IN ('Video','Image','Certificate')),
    CONSTRAINT [CK_MediaAssets_02] CHECK ([ProcessingStatus] IN ('Pending','Processing','Ready','Failed')),
    CONSTRAINT [CK_MediaAssets_03] CHECK ([SizeBytes] >= 0),
    CONSTRAINT [CK_MediaAssets_04] CHECK ([DurationSeconds] IS NULL OR [DurationSeconds] >= 0)
);
GO
CREATE UNIQUE INDEX [UX_MediaAssets_BlobKey] ON [dbo].[MediaAssets] ([BlobKey]);
CREATE INDEX [IX_MediaAssets_UploadedByUserId_CreatedAt] ON [dbo].[MediaAssets] ([UploadedByUserId], [CreatedAt]);
GO

-- Catalog / Tag
CREATE TABLE [dbo].[Tags] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Name] nvarchar(80) NOT NULL,
    [Slug] nvarchar(100) NOT NULL,
    CONSTRAINT [PK_Tags] PRIMARY KEY ([Id])
);
GO
CREATE UNIQUE INDEX [UX_Tags_Slug] ON [dbo].[Tags] ([Slug]);
GO

-- Commerce / Cart
CREATE TABLE [dbo].[Carts] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [UserId] nvarchar(450) NOT NULL,
    [UpdatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_Carts] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Carts_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION
);
GO
CREATE UNIQUE INDEX [UX_Carts_UserId] ON [dbo].[Carts] ([UserId]);
GO

-- Commerce / Order
CREATE TABLE [dbo].[Orders] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [BuyerUserId] nvarchar(450) NOT NULL,
    [OrderNumber] varchar(40) NOT NULL,
    [Currency] char(3) NOT NULL,
    [SubtotalAmount] decimal(18,2) NOT NULL DEFAULT (0),
    [DiscountAmount] decimal(18,2) NOT NULL DEFAULT (0),
    [TotalAmount] decimal(18,2) NOT NULL DEFAULT (0),
    [Status] varchar(20) NOT NULL DEFAULT 'Pending',
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [PaidAt] datetime2(3) NULL,
    CONSTRAINT [PK_Orders] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Orders_Users_BuyerUserId] FOREIGN KEY ([BuyerUserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_Orders_01] CHECK ([SubtotalAmount] >= 0),
    CONSTRAINT [CK_Orders_02] CHECK ([DiscountAmount] >= 0),
    CONSTRAINT [CK_Orders_03] CHECK ([TotalAmount] >= 0),
    CONSTRAINT [CK_Orders_04] CHECK ([TotalAmount] = [SubtotalAmount] - [DiscountAmount]),
    CONSTRAINT [CK_Orders_05] CHECK ([Status] IN ('Pending','Paid','Failed','Canceled','Refunded'))
);
GO
CREATE UNIQUE INDEX [UX_Orders_OrderNumber] ON [dbo].[Orders] ([OrderNumber]);
CREATE INDEX [IX_Orders_BuyerUserId_CreatedAt] ON [dbo].[Orders] ([BuyerUserId], [CreatedAt]);
GO

-- Commerce / Coupon
CREATE TABLE [dbo].[Coupons] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [Code] varchar(60) NOT NULL,
    [DiscountType] varchar(12) NOT NULL,
    [DiscountValue] decimal(18,2) NOT NULL,
    [ValidFrom] datetime2(3) NULL,
    [ValidUntil] datetime2(3) NULL,
    [MaxRedemptions] int NULL,
    [IsActive] bit NOT NULL DEFAULT (1),
    CONSTRAINT [PK_Coupons] PRIMARY KEY ([Id]),
    CONSTRAINT [CK_Coupons_01] CHECK ([DiscountType] IN ('Percentage','Fixed')),
    CONSTRAINT [CK_Coupons_02] CHECK ([DiscountValue] > 0),
    CONSTRAINT [CK_Coupons_03] CHECK (([DiscountType] <> 'Percentage' OR [DiscountValue] <= 100)),
    CONSTRAINT [CK_Coupons_04] CHECK ([MaxRedemptions] IS NULL OR [MaxRedemptions] > 0),
    CONSTRAINT [CK_Coupons_05] CHECK ([ValidUntil] IS NULL OR [ValidFrom] IS NULL OR [ValidUntil] > [ValidFrom])
);
GO
CREATE UNIQUE INDEX [UX_Coupons_Code] ON [dbo].[Coupons] ([Code]);
GO

-- Engagement / Notification
CREATE TABLE [dbo].[Notifications] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [RecipientUserId] nvarchar(450) NOT NULL,
    [Type] varchar(40) NOT NULL,
    [Title] nvarchar(180) NOT NULL,
    [Body] nvarchar(2000) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [ReadAt] datetime2(3) NULL,
    CONSTRAINT [PK_Notifications] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Notifications_Users_RecipientUserId] FOREIGN KEY ([RecipientUserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION
);
GO
CREATE INDEX [IX_Notifications_RecipientUserId_ReadAt_CreatedAt] ON [dbo].[Notifications] ([RecipientUserId], [ReadAt], [CreatedAt]);
GO

-- Catalog / Course
CREATE TABLE [dbo].[Courses] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [InstructorUserId] nvarchar(450) NOT NULL,
    [CategoryId] bigint NOT NULL,
    [ThumbnailMediaId] bigint NULL,
    [Title] nvarchar(200) NOT NULL,
    [Slug] nvarchar(220) NOT NULL,
    [Description] nvarchar(max) NOT NULL,
    [Level] varchar(20) NOT NULL,
    [PriceAmount] decimal(18,2) NOT NULL DEFAULT (0),
    [Currency] char(3) NOT NULL,
    [Status] varchar(24) NOT NULL DEFAULT 'Draft',
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [PublishedAt] datetime2(3) NULL,
    [RowVersion] rowversion,
    CONSTRAINT [PK_Courses] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Courses_InstructorProfiles_InstructorUserId] FOREIGN KEY ([InstructorUserId]) REFERENCES [dbo].[InstructorProfiles] ([UserId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Courses_Categories_CategoryId] FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[Categories] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Courses_MediaAssets_ThumbnailMediaId] FOREIGN KEY ([ThumbnailMediaId]) REFERENCES [dbo].[MediaAssets] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_Courses_01] CHECK ([Level] IN ('Beginner','Intermediate','Advanced','AllLevels')),
    CONSTRAINT [CK_Courses_02] CHECK ([Status] IN ('Draft','PendingApproval','Published','Rejected','Archived')),
    CONSTRAINT [CK_Courses_03] CHECK ([PriceAmount] >= 0)
);
GO
CREATE UNIQUE INDEX [UX_Courses_Slug] ON [dbo].[Courses] ([Slug]);
CREATE INDEX [IX_Courses_InstructorUserId_Status] ON [dbo].[Courses] ([InstructorUserId], [Status]);
CREATE INDEX [IX_Courses_CategoryId_Status] ON [dbo].[Courses] ([CategoryId], [Status]);
GO

-- Commerce / PaymentTransaction
CREATE TABLE [dbo].[PaymentTransactions] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [OrderId] bigint NOT NULL,
    [Provider] varchar(20) NOT NULL DEFAULT 'Stripe',
    [StripeObjectId] varchar(255) NULL,
    [Amount] decimal(18,2) NOT NULL,
    [Currency] char(3) NOT NULL,
    [Status] varchar(20) NOT NULL DEFAULT 'Pending',
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [CompletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_PaymentTransactions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_PaymentTransactions_Orders_OrderId] FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Orders] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_PaymentTransactions_01] CHECK ([Amount] >= 0),
    CONSTRAINT [CK_PaymentTransactions_02] CHECK ([Provider] IN ('Stripe')),
    CONSTRAINT [CK_PaymentTransactions_03] CHECK ([Status] IN ('Pending','Succeeded','Failed','Canceled','Refunded'))
);
GO
CREATE UNIQUE INDEX [UX_PaymentTransactions_StripeObjectId] ON [dbo].[PaymentTransactions] ([StripeObjectId]) WHERE [StripeObjectId] IS NOT NULL;
CREATE INDEX [IX_PaymentTransactions_OrderId_CreatedAt] ON [dbo].[PaymentTransactions] ([OrderId], [CreatedAt]);
GO

-- Commerce / CouponRedemption
CREATE TABLE [dbo].[CouponRedemptions] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [CouponId] bigint NOT NULL,
    [OrderId] bigint NOT NULL,
    [UserId] nvarchar(450) NOT NULL,
    [AppliedAmount] decimal(18,2) NOT NULL,
    [Status] varchar(16) NOT NULL DEFAULT 'Pending',
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_CouponRedemptions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_CouponRedemptions_Coupons_CouponId] FOREIGN KEY ([CouponId]) REFERENCES [dbo].[Coupons] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CouponRedemptions_Orders_OrderId] FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Orders] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CouponRedemptions_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_CouponRedemptions_01] CHECK ([AppliedAmount] >= 0),
    CONSTRAINT [CK_CouponRedemptions_02] CHECK ([Status] IN ('Pending','Applied','Reverted'))
);
GO
CREATE UNIQUE INDEX [UX_CouponRedemptions_OrderId] ON [dbo].[CouponRedemptions] ([OrderId]);
CREATE INDEX [IX_CouponRedemptions_CouponId_Status] ON [dbo].[CouponRedemptions] ([CouponId], [Status]);
GO

-- Catalog / CourseSection
CREATE TABLE [dbo].[CourseSections] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [CourseId] bigint NOT NULL,
    [Title] nvarchar(180) NOT NULL,
    [Description] nvarchar(1000) NULL,
    [SortOrder] int NOT NULL,
    CONSTRAINT [PK_CourseSections] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_CourseSections_Courses_CourseId] FOREIGN KEY ([CourseId]) REFERENCES [dbo].[Courses] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_CourseSections_01] CHECK ([SortOrder] >= 0)
);
GO
CREATE UNIQUE INDEX [UX_CourseSections_CourseId_SortOrder] ON [dbo].[CourseSections] ([CourseId], [SortOrder]);
GO

-- Catalog / CourseTag
CREATE TABLE [dbo].[CourseTags] (
    [CourseId] bigint NOT NULL,
    [TagId] bigint NOT NULL,
    CONSTRAINT [PK_CourseTags] PRIMARY KEY ([CourseId], [TagId]),
    CONSTRAINT [FK_CourseTags_Courses_CourseId] FOREIGN KEY ([CourseId]) REFERENCES [dbo].[Courses] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CourseTags_Tags_TagId] FOREIGN KEY ([TagId]) REFERENCES [dbo].[Tags] ([Id]) ON DELETE NO ACTION
);
GO
CREATE INDEX [IX_CourseTags_TagId_CourseId] ON [dbo].[CourseTags] ([TagId], [CourseId]);
GO

-- Governance / CourseApproval
CREATE TABLE [dbo].[CourseApprovals] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [CourseId] bigint NOT NULL,
    [ReviewerUserId] nvarchar(450) NULL,
    [Decision] varchar(20) NOT NULL DEFAULT 'Pending',
    [Comments] nvarchar(1000) NULL,
    [RequestedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [DecidedAt] datetime2(3) NULL,
    CONSTRAINT [PK_CourseApprovals] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_CourseApprovals_Courses_CourseId] FOREIGN KEY ([CourseId]) REFERENCES [dbo].[Courses] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CourseApprovals_Users_ReviewerUserId] FOREIGN KEY ([ReviewerUserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_CourseApprovals_01] CHECK ([Decision] IN ('Pending','Approved','Rejected'))
);
GO
CREATE INDEX [IX_CourseApprovals_CourseId_RequestedAt] ON [dbo].[CourseApprovals] ([CourseId], [RequestedAt]);
GO

-- Governance / CourseAnnouncement
CREATE TABLE [dbo].[CourseAnnouncements] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [CourseId] bigint NOT NULL,
    [AuthorUserId] nvarchar(450) NOT NULL,
    [Title] nvarchar(180) NOT NULL,
    [Body] nvarchar(max) NOT NULL,
    [PublishedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_CourseAnnouncements] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_CourseAnnouncements_Courses_CourseId] FOREIGN KEY ([CourseId]) REFERENCES [dbo].[Courses] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CourseAnnouncements_Users_AuthorUserId] FOREIGN KEY ([AuthorUserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION
);
GO
CREATE INDEX [IX_CourseAnnouncements_CourseId_PublishedAt] ON [dbo].[CourseAnnouncements] ([CourseId], [PublishedAt]);
GO

-- Commerce / CartItem
CREATE TABLE [dbo].[CartItems] (
    [CartId] bigint NOT NULL,
    [CourseId] bigint NOT NULL,
    [AddedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_CartItems] PRIMARY KEY ([CartId], [CourseId]),
    CONSTRAINT [FK_CartItems_Carts_CartId] FOREIGN KEY ([CartId]) REFERENCES [dbo].[Carts] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CartItems_Courses_CourseId] FOREIGN KEY ([CourseId]) REFERENCES [dbo].[Courses] ([Id]) ON DELETE NO ACTION
);
GO
CREATE INDEX [IX_CartItems_CourseId] ON [dbo].[CartItems] ([CourseId]);
GO

-- Commerce / OrderItem
CREATE TABLE [dbo].[OrderItems] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [OrderId] bigint NOT NULL,
    [CourseId] bigint NOT NULL,
    [InstructorUserId] nvarchar(450) NOT NULL,
    [TitleSnapshot] nvarchar(200) NOT NULL,
    [UnitPriceAmount] decimal(18,2) NOT NULL,
    [DiscountAmount] decimal(18,2) NOT NULL DEFAULT (0),
    [FinalAmount] decimal(18,2) NOT NULL,
    CONSTRAINT [PK_OrderItems] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_OrderItems_Orders_OrderId] FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Orders] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_OrderItems_Courses_CourseId] FOREIGN KEY ([CourseId]) REFERENCES [dbo].[Courses] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_OrderItems_InstructorProfiles_InstructorUserId] FOREIGN KEY ([InstructorUserId]) REFERENCES [dbo].[InstructorProfiles] ([UserId]) ON DELETE NO ACTION,
    CONSTRAINT [CK_OrderItems_01] CHECK ([UnitPriceAmount] >= 0),
    CONSTRAINT [CK_OrderItems_02] CHECK ([DiscountAmount] >= 0),
    CONSTRAINT [CK_OrderItems_03] CHECK ([FinalAmount] >= 0),
    CONSTRAINT [CK_OrderItems_04] CHECK ([FinalAmount] = [UnitPriceAmount] - [DiscountAmount])
);
GO
CREATE UNIQUE INDEX [UX_OrderItems_OrderId_CourseId] ON [dbo].[OrderItems] ([OrderId], [CourseId]);
CREATE INDEX [IX_OrderItems_CourseId] ON [dbo].[OrderItems] ([CourseId]);
GO

-- Commerce / PaymentWebhookEvent
CREATE TABLE [dbo].[PaymentWebhookEvents] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [PaymentTransactionId] bigint NULL,
    [StripeEventId] varchar(255) NOT NULL,
    [EventType] varchar(120) NOT NULL,
    [PayloadHash] char(64) NULL,
    [Status] varchar(20) NOT NULL DEFAULT 'Received',
    [ReceivedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [ProcessedAt] datetime2(3) NULL,
    [LastError] nvarchar(1000) NULL,
    CONSTRAINT [PK_PaymentWebhookEvents] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_PaymentWebhookEvents_PaymentTransactions_PaymentTransactionId] FOREIGN KEY ([PaymentTransactionId]) REFERENCES [dbo].[PaymentTransactions] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_PaymentWebhookEvents_01] CHECK ([Status] IN ('Received','Processed','Failed','Ignored'))
);
GO
CREATE UNIQUE INDEX [UX_PaymentWebhookEvents_StripeEventId] ON [dbo].[PaymentWebhookEvents] ([StripeEventId]);
CREATE INDEX [IX_PaymentWebhookEvents_Status_ReceivedAt] ON [dbo].[PaymentWebhookEvents] ([Status], [ReceivedAt]);
GO

-- Engagement / CourseQuestion
CREATE TABLE [dbo].[CourseQuestions] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [CourseId] bigint NOT NULL,
    [AuthorUserId] nvarchar(450) NOT NULL,
    [Title] nvarchar(180) NOT NULL,
    [Body] nvarchar(max) NOT NULL,
    [IsResolved] bit NOT NULL DEFAULT (0),
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_CourseQuestions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_CourseQuestions_Courses_CourseId] FOREIGN KEY ([CourseId]) REFERENCES [dbo].[Courses] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CourseQuestions_Users_AuthorUserId] FOREIGN KEY ([AuthorUserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION
);
GO
CREATE INDEX [IX_CourseQuestions_CourseId_CreatedAt] ON [dbo].[CourseQuestions] ([CourseId], [CreatedAt]);
GO

-- Catalog / Lesson
CREATE TABLE [dbo].[Lessons] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [SectionId] bigint NOT NULL,
    [VideoMediaId] bigint NULL,
    [Title] nvarchar(180) NOT NULL,
    [ContentHtml] nvarchar(max) NULL,
    [DurationSeconds] int NOT NULL DEFAULT (0),
    [SortOrder] int NOT NULL,
    [IsPreview] bit NOT NULL DEFAULT (0),
    CONSTRAINT [PK_Lessons] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Lessons_CourseSections_SectionId] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[CourseSections] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Lessons_MediaAssets_VideoMediaId] FOREIGN KEY ([VideoMediaId]) REFERENCES [dbo].[MediaAssets] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_Lessons_01] CHECK ([SortOrder] >= 0),
    CONSTRAINT [CK_Lessons_02] CHECK ([DurationSeconds] >= 0)
);
GO
CREATE UNIQUE INDEX [UX_Lessons_SectionId_SortOrder] ON [dbo].[Lessons] ([SectionId], [SortOrder]);
CREATE INDEX [IX_Lessons_VideoMediaId] ON [dbo].[Lessons] ([VideoMediaId]);
GO

-- Commerce / InstructorEarning
CREATE TABLE [dbo].[InstructorEarnings] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [OrderItemId] bigint NOT NULL,
    [InstructorUserId] nvarchar(450) NOT NULL,
    [EntryType] varchar(20) NOT NULL,
    [EventRef] varchar(100) NOT NULL,
    [Amount] decimal(18,2) NOT NULL,
    [Currency] char(3) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_InstructorEarnings] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_InstructorEarnings_OrderItems_OrderItemId] FOREIGN KEY ([OrderItemId]) REFERENCES [dbo].[OrderItems] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_InstructorEarnings_InstructorProfiles_InstructorUserId] FOREIGN KEY ([InstructorUserId]) REFERENCES [dbo].[InstructorProfiles] ([UserId]) ON DELETE NO ACTION,
    CONSTRAINT [CK_InstructorEarnings_01] CHECK ([EntryType] IN ('Credit','Reversal','Adjustment')),
    CONSTRAINT [CK_InstructorEarnings_02] CHECK (([EntryType] = 'Credit' AND [Amount] >= 0) OR ([EntryType] = 'Reversal' AND [Amount] <= 0) OR [EntryType] = 'Adjustment')
);
GO
CREATE UNIQUE INDEX [UX_InstructorEarnings_OrderItemId_EventRef] ON [dbo].[InstructorEarnings] ([OrderItemId], [EventRef]);
CREATE INDEX [IX_InstructorEarnings_InstructorUserId_CreatedAt] ON [dbo].[InstructorEarnings] ([InstructorUserId], [CreatedAt]);
GO

-- Learning / Enrollment
CREATE TABLE [dbo].[Enrollments] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [StudentUserId] nvarchar(450) NOT NULL,
    [CourseId] bigint NOT NULL,
    [OrderItemId] bigint NULL,
    [Status] varchar(20) NOT NULL DEFAULT 'Active',
    [EnrolledAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [CompletedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Enrollments] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Enrollments_StudentProfiles_StudentUserId] FOREIGN KEY ([StudentUserId]) REFERENCES [dbo].[StudentProfiles] ([UserId]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Enrollments_Courses_CourseId] FOREIGN KEY ([CourseId]) REFERENCES [dbo].[Courses] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Enrollments_OrderItems_OrderItemId] FOREIGN KEY ([OrderItemId]) REFERENCES [dbo].[OrderItems] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_Enrollments_01] CHECK ([Status] IN ('Active','Completed','Revoked'))
);
GO
CREATE UNIQUE INDEX [UX_Enrollments_StudentUserId_CourseId] ON [dbo].[Enrollments] ([StudentUserId], [CourseId]);
CREATE UNIQUE INDEX [UX_Enrollments_OrderItemId] ON [dbo].[Enrollments] ([OrderItemId]) WHERE [OrderItemId] IS NOT NULL;
CREATE INDEX [IX_Enrollments_CourseId_Status] ON [dbo].[Enrollments] ([CourseId], [Status]);
GO

-- Assessment / Quiz
CREATE TABLE [dbo].[Quizzes] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [CourseId] bigint NOT NULL,
    [SectionId] bigint NULL,
    [Title] nvarchar(160) NOT NULL,
    [PassScore] decimal(5,2) NOT NULL DEFAULT (60),
    [MaxAttempts] smallint NULL,
    [IsPublished] bit NOT NULL DEFAULT (0),
    CONSTRAINT [PK_Quizzes] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Quizzes_Courses_CourseId] FOREIGN KEY ([CourseId]) REFERENCES [dbo].[Courses] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Quizzes_CourseSections_SectionId] FOREIGN KEY ([SectionId]) REFERENCES [dbo].[CourseSections] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_Quizzes_01] CHECK ([PassScore] >= 0 AND [PassScore] <= 100),
    CONSTRAINT [CK_Quizzes_02] CHECK ([MaxAttempts] IS NULL OR [MaxAttempts] > 0)
);
GO
CREATE INDEX [IX_Quizzes_CourseId_SectionId] ON [dbo].[Quizzes] ([CourseId], [SectionId]);
GO

-- Engagement / CourseAnswer
CREATE TABLE [dbo].[CourseAnswers] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [QuestionId] bigint NOT NULL,
    [AuthorUserId] nvarchar(450) NOT NULL,
    [Body] nvarchar(max) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_CourseAnswers] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_CourseAnswers_CourseQuestions_QuestionId] FOREIGN KEY ([QuestionId]) REFERENCES [dbo].[CourseQuestions] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_CourseAnswers_Users_AuthorUserId] FOREIGN KEY ([AuthorUserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION
);
GO
CREATE INDEX [IX_CourseAnswers_QuestionId_CreatedAt] ON [dbo].[CourseAnswers] ([QuestionId], [CreatedAt]);
GO

-- Learning / LessonProgress
CREATE TABLE [dbo].[LessonProgresses] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [EnrollmentId] bigint NOT NULL,
    [LessonId] bigint NOT NULL,
    [LastPositionSeconds] int NOT NULL DEFAULT (0),
    [IsCompleted] bit NOT NULL DEFAULT (0),
    [CompletedAt] datetime2(3) NULL,
    [UpdatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_LessonProgresses] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_LessonProgresses_Enrollments_EnrollmentId] FOREIGN KEY ([EnrollmentId]) REFERENCES [dbo].[Enrollments] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_LessonProgresses_Lessons_LessonId] FOREIGN KEY ([LessonId]) REFERENCES [dbo].[Lessons] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_LessonProgresses_01] CHECK ([LastPositionSeconds] >= 0)
);
GO
CREATE UNIQUE INDEX [UX_LessonProgresses_EnrollmentId_LessonId] ON [dbo].[LessonProgresses] ([EnrollmentId], [LessonId]);
CREATE INDEX [IX_LessonProgresses_LessonId] ON [dbo].[LessonProgresses] ([LessonId]);
GO

-- Learning / LessonNote
CREATE TABLE [dbo].[LessonNotes] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [EnrollmentId] bigint NOT NULL,
    [LessonId] bigint NOT NULL,
    [TimeSeconds] int NOT NULL DEFAULT (0),
    [Body] nvarchar(2000) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [UpdatedAt] datetime2(3) NULL,
    CONSTRAINT [PK_LessonNotes] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_LessonNotes_Enrollments_EnrollmentId] FOREIGN KEY ([EnrollmentId]) REFERENCES [dbo].[Enrollments] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_LessonNotes_Lessons_LessonId] FOREIGN KEY ([LessonId]) REFERENCES [dbo].[Lessons] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_LessonNotes_01] CHECK ([TimeSeconds] >= 0)
);
GO
CREATE INDEX [IX_LessonNotes_EnrollmentId_LessonId_TimeSeconds] ON [dbo].[LessonNotes] ([EnrollmentId], [LessonId], [TimeSeconds]);
GO

-- Learning / LessonBookmark
CREATE TABLE [dbo].[LessonBookmarks] (
    [EnrollmentId] bigint NOT NULL,
    [LessonId] bigint NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_LessonBookmarks] PRIMARY KEY ([EnrollmentId], [LessonId]),
    CONSTRAINT [FK_LessonBookmarks_Enrollments_EnrollmentId] FOREIGN KEY ([EnrollmentId]) REFERENCES [dbo].[Enrollments] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_LessonBookmarks_Lessons_LessonId] FOREIGN KEY ([LessonId]) REFERENCES [dbo].[Lessons] ([Id]) ON DELETE NO ACTION
);
GO
CREATE INDEX [IX_LessonBookmarks_LessonId] ON [dbo].[LessonBookmarks] ([LessonId]);
GO

-- Assessment / QuizQuestion
CREATE TABLE [dbo].[QuizQuestions] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [QuizId] bigint NOT NULL,
    [QuestionType] varchar(20) NOT NULL,
    [Prompt] nvarchar(max) NOT NULL,
    [CorrectText] nvarchar(500) NULL,
    [Points] decimal(6,2) NOT NULL DEFAULT (1),
    [SortOrder] int NOT NULL,
    CONSTRAINT [PK_QuizQuestions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_QuizQuestions_Quizzes_QuizId] FOREIGN KEY ([QuizId]) REFERENCES [dbo].[Quizzes] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_QuizQuestions_01] CHECK ([QuestionType] IN ('MultipleChoice','TrueFalse','FillBlank')),
    CONSTRAINT [CK_QuizQuestions_02] CHECK ([Points] > 0),
    CONSTRAINT [CK_QuizQuestions_03] CHECK ([SortOrder] >= 0)
);
GO
CREATE UNIQUE INDEX [UX_QuizQuestions_QuizId_SortOrder] ON [dbo].[QuizQuestions] ([QuizId], [SortOrder]);
GO

-- Assessment / QuizAttempt
CREATE TABLE [dbo].[QuizAttempts] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [QuizId] bigint NOT NULL,
    [EnrollmentId] bigint NOT NULL,
    [AttemptNumber] smallint NOT NULL,
    [ScorePercentage] decimal(5,2) NULL,
    [Status] varchar(20) NOT NULL DEFAULT 'InProgress',
    [StartedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [SubmittedAt] datetime2(3) NULL,
    CONSTRAINT [PK_QuizAttempts] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_QuizAttempts_Quizzes_QuizId] FOREIGN KEY ([QuizId]) REFERENCES [dbo].[Quizzes] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_QuizAttempts_Enrollments_EnrollmentId] FOREIGN KEY ([EnrollmentId]) REFERENCES [dbo].[Enrollments] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_QuizAttempts_01] CHECK ([AttemptNumber] > 0),
    CONSTRAINT [CK_QuizAttempts_02] CHECK ([ScorePercentage] IS NULL OR ([ScorePercentage] >= 0 AND [ScorePercentage] <= 100)),
    CONSTRAINT [CK_QuizAttempts_03] CHECK ([Status] IN ('InProgress','Submitted','Graded'))
);
GO
CREATE UNIQUE INDEX [UX_QuizAttempts_QuizId_EnrollmentId_AttemptNumber] ON [dbo].[QuizAttempts] ([QuizId], [EnrollmentId], [AttemptNumber]);
CREATE INDEX [IX_QuizAttempts_EnrollmentId_Status] ON [dbo].[QuizAttempts] ([EnrollmentId], [Status]);
GO

-- Certification / Certificate
CREATE TABLE [dbo].[Certificates] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [EnrollmentId] bigint NOT NULL,
    [VerifyCode] varchar(80) NOT NULL,
    [PdfBlobKey] nvarchar(500) NOT NULL,
    [IssuedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [IsRevoked] bit NOT NULL DEFAULT (0),
    [RevokedAt] datetime2(3) NULL,
    CONSTRAINT [PK_Certificates] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Certificates_Enrollments_EnrollmentId] FOREIGN KEY ([EnrollmentId]) REFERENCES [dbo].[Enrollments] ([Id]) ON DELETE NO ACTION
);
GO
CREATE UNIQUE INDEX [UX_Certificates_EnrollmentId] ON [dbo].[Certificates] ([EnrollmentId]);
CREATE UNIQUE INDEX [UX_Certificates_VerifyCode] ON [dbo].[Certificates] ([VerifyCode]);
GO

-- Engagement / CourseReview
CREATE TABLE [dbo].[CourseReviews] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [EnrollmentId] bigint NOT NULL,
    [Rating] tinyint NOT NULL,
    [Body] nvarchar(2000) NULL,
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    [UpdatedAt] datetime2(3) NULL,
    CONSTRAINT [PK_CourseReviews] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_CourseReviews_Enrollments_EnrollmentId] FOREIGN KEY ([EnrollmentId]) REFERENCES [dbo].[Enrollments] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_CourseReviews_01] CHECK ([Rating] BETWEEN 1 AND 5)
);
GO
CREATE UNIQUE INDEX [UX_CourseReviews_EnrollmentId] ON [dbo].[CourseReviews] ([EnrollmentId]);
GO

-- Assessment / QuizOption
CREATE TABLE [dbo].[QuizOptions] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [QuestionId] bigint NOT NULL,
    [Text] nvarchar(500) NOT NULL,
    [IsCorrect] bit NOT NULL DEFAULT (0),
    [SortOrder] int NOT NULL,
    CONSTRAINT [PK_QuizOptions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_QuizOptions_QuizQuestions_QuestionId] FOREIGN KEY ([QuestionId]) REFERENCES [dbo].[QuizQuestions] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_QuizOptions_01] CHECK ([SortOrder] >= 0)
);
GO
CREATE UNIQUE INDEX [UX_QuizOptions_QuestionId_SortOrder] ON [dbo].[QuizOptions] ([QuestionId], [SortOrder]);
GO

-- Engagement / ReviewHelpfulVote
CREATE TABLE [dbo].[ReviewHelpfulVotes] (
    [ReviewId] bigint NOT NULL,
    [VoterUserId] nvarchar(450) NOT NULL,
    [CreatedAt] datetime2(3) NOT NULL DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_ReviewHelpfulVotes] PRIMARY KEY ([ReviewId], [VoterUserId]),
    CONSTRAINT [FK_ReviewHelpfulVotes_CourseReviews_ReviewId] FOREIGN KEY ([ReviewId]) REFERENCES [dbo].[CourseReviews] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_ReviewHelpfulVotes_Users_VoterUserId] FOREIGN KEY ([VoterUserId]) REFERENCES [dbo].[Users] ([Id]) ON DELETE NO ACTION
);
GO
CREATE INDEX [IX_ReviewHelpfulVotes_VoterUserId] ON [dbo].[ReviewHelpfulVotes] ([VoterUserId]);
GO

-- Assessment / QuizAnswer
CREATE TABLE [dbo].[QuizAnswers] (
    [Id] bigint IDENTITY(1,1) NOT NULL,
    [AttemptId] bigint NOT NULL,
    [QuestionId] bigint NOT NULL,
    [OptionId] bigint NULL,
    [TextAnswer] nvarchar(500) NULL,
    [PointsEarned] decimal(6,2) NOT NULL DEFAULT (0),
    CONSTRAINT [PK_QuizAnswers] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_QuizAnswers_QuizAttempts_AttemptId] FOREIGN KEY ([AttemptId]) REFERENCES [dbo].[QuizAttempts] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_QuizAnswers_QuizQuestions_QuestionId] FOREIGN KEY ([QuestionId]) REFERENCES [dbo].[QuizQuestions] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_QuizAnswers_QuizOptions_OptionId] FOREIGN KEY ([OptionId]) REFERENCES [dbo].[QuizOptions] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [CK_QuizAnswers_01] CHECK ([PointsEarned] >= 0)
);
GO
CREATE UNIQUE INDEX [UX_QuizAnswers_AttemptId_QuestionId] ON [dbo].[QuizAnswers] ([AttemptId], [QuestionId]);
CREATE INDEX [IX_QuizAnswers_QuestionId] ON [dbo].[QuizAnswers] ([QuestionId]);
GO

-- Data-integrity rules beyond ordinary FKs:
-- 1) Check lesson/course and quiz/enrollment course consistency inside transactional services.
-- 2) Validate order currency and sum of OrderItems against Orders totals atomically.
-- 3) Validate payment signature and provider object before fulfillment.
-- 4) Enforce role/ownership authorization with application policy checks.
-- 5) Invalidate access by setting Enrollment.Status=Revoked, not deleting paid history.
-- 6) Ensure Category parent hierarchy is cycle-free and Lesson video asset is a video.
-- 7) Explicitly configure EF Core model, including rowversion and filtered unique indexes.
