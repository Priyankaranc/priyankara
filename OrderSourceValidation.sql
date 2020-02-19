USE [Rocky_EDI]
GO
/****** Object:  StoredProcedure [Rule].[CheckOrderSource]    Script Date: 2/6/2020 11:11:26 AM ******/
IF EXISTS ( SELECT * 
            FROM   sysobjects 
            WHERE  id = object_id(N'[Rule].[CheckOrderSource]') 
                   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [Rule].[CheckOrderSource]
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Niranga Dissanayake
-- Create date: 2020-02-06
-- Description:	Check order source values 
-- =============================================
CREATE PROCEDURE [Rule].[CheckOrderSource] 
	-- Add the parameters for the stored procedure here
	@input varchar(max)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @outputString VARCHAR(MAX)
    DECLARE @output VARCHAR(MAX)

	-- get cono from initial input
	
	DECLARE @OrderId varchar(max) = JSON_VALUE(@input,'$.OrderId');

	-- get OrderSource from order header
	DECLARE @OrderSource int = (SELECT NewOrderSource FROM [Order].OrderHeader WHERE Id = @OrderId)
	
	--set @OrderSource = 0  -- for testing purpose
	
	IF @OrderSource = 0 OR @OrderSource IS NULL
		BEGIN
			-- set validation messages if OrderSource is null
			SET @outputString = (SELECT	'Order Source cannot be blank' as 'Message', 'NewOrderSource' as 'FieldName', 1 as 'IsHardStop', 'OrderHeader' as 'ValidationType', @OrderId as 'Id'
								FOR JSON PATH, INCLUDE_NULL_VALUES)

			-- output
			SET @output = JSON_MODIFY(@input, '$.Validations', JSON_QUERY(@outputString))
		    SELECT @output
		END
	ELSE
		BEGIN
			-- output
			SET @output = JSON_MODIFY(@input, '$.CheckOrderSource', JSON_QUERY(@outputString))
			SELECT @output
		END
	
END
GO
/****** Object:  StoredProcedure [Rule].[ValidateOrderSource]    Script Date: 2/6/2020 11:11:26 AM ******/
IF EXISTS ( SELECT * 
            FROM   sysobjects 
            WHERE  id = object_id(N'[Rule].[ValidateOrderSource]') 
                   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [Rule].[ValidateOrderSource]
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Niranga Dissanayake
-- Create date: 2020-02-06
-- Description:	validate order source against m3
-- =============================================
CREATE PROCEDURE 
[Rule].[ValidateOrderSource]
	-- Add the parameters for the stored procedure here
	@input varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	DECLARE @output varchar(max)
	DECLARE @outputString varchar(max)

	SET @outputString = (SELECT 'true' AS IsExit 
                                         FOR JSON PATH, INCLUDE_NULL_VALUES) 
	
	DECLARE @OrderId varchar(max) = JSON_VALUE(@input,'$.OrderId');

	-- get the OrderSource value
	DECLARE @OrderSource int = (SELECT NewOrderSource FROM [Order].OrderHeader WHERE Id = 226= @OrderId)

    -- SELECT @output
	IF @OrderSource is NOT NULL
	  begin
		SET @outputString = (SELECT  
								'CRS881MI' AS Program, 
								'GetTranslData' AS [Transaction], 
								'MBMD' AS OutputField, 
								'TRQF=E&MSTD=X12&MVRS=4010&BMSG=850&IBOB=I&ELMP=Order_Source&ELMD=Order_Source&MBMD='+@OrderSource+'' AS [Parameters]					
						FOR JSON PATH, INCLUDE_NULL_VALUES
						)
	  end
	  -- output
	  SET @output = JSON_MODIFY(@input, '$.ValidateOrderSource', JSON_QUERY(@outputString))

	SELECT @output

	
	
END
GO
/****** Object:  StoredProcedure [Rule].[UpdateOrderSourceValues]    Script Date: 2/6/2020 11:11:26 AM ******/
IF EXISTS ( SELECT * 
            FROM   sysobjects 
            WHERE  id = object_id(N'[Rule].[UpdateOrderSourceValues]') 
                   and OBJECTPROPERTY(id, N'IsProcedure') = 1 )
BEGIN
    DROP PROCEDURE [Rule].[UpdateOrderSourceValues]
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Niranga Dissanayake
-- Create date: 2020-02-06
-- Description:	Update the tables after the validations
-- =============================================
CREATE PROCEDURE [Rule].[UpdateOrderSourceValues] 
	-- Add the parameters for the stored procedure here
	@input varchar(max)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;

    DECLARE @outputString VARCHAR(MAX)
    DECLARE @output VARCHAR(MAX)

	-- get cono from initial input
	DECLARE @OrderId varchar(max) = JSON_VALUE(@input,'$.OrderId');
	
	DECLARE @m3OutPut varchar(max) = JSON_VALUE(@input,'$.ValidateOrderSource[0].OutputValue');
	
	
	IF @m3OutPut IS Not NULL
		BEGIN
			-- set validation messages if address code is not matched in M3
			DECLARE @currentOrderSourcevalue int = (select h.NewM3OrderSource from [Order].OrderHeader h WHERE h.Id = @OrderId)

			update  [Order].OrderHeader  SET OldM3OrderSource = @currentOrderSourcevalue  WHERE Id = @OrderId
			update  [Order].OrderHeader SET NewM3OrderSource = @m3OutPut WHERE Id = @OrderId

		END
	ELSE
		BEGIN

			SET @outputString = (SELECT	'Order Source not defined' as 'Message', 'NewOrderSource' as 'FieldName', 1 as 'IsHardStop', 'OrderHeader' as 'ValidationType', @OrderId as 'Id'
								FOR JSON PATH, INCLUDE_NULL_VALUES)

			SET @output = JSON_MODIFY(@input, '$.Validations', JSON_QUERY(@outputString))
		    SELECT @output

		END
		
	
	-- output
	SET @output = JSON_MODIFY(@input, '$.UpdateOrderSourceValues', JSON_QUERY(@outputString))
	SELECT @output

END
GO
