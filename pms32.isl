/////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	//				                   RUI TIP SIM
	// Custom Payroll Tip Report printing from micros terminals
	// Custom Clock In / Out
	// September 2010
	// Jeffery Hayes
	// pms32.isl - interface #32 in Devices>Interfaces
/////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

//variables

var RestaurantID   	: A3 	//RestaurantID - not currently used
var TerminalID		: A20	//define terminal name - not currently used
var EmpNumber		: A50 	//define employee number - object number
var EmpName			: A50	//define employee name - first and last name
var EmpSeq			: A50  	//define employee sequence number - emp_seq
var empPW			: A16  	//define employee id
var magSecurity		: A15 	//remember if card was swiped
var ShiftNum		: A5	//define shift number - current shift number
var DateTime		: A50  	//define current date and time 
var CurPPstart		: A50 	//define date range - Current PayPeriod Start Date
var CurPPend		: A50 	//define date range - Current PayPeriod EndDate
var curPPpaydate	: A50 	//define pay day for current pay period
var LastPPstart		: A50 	//define Last PayPeriod Start Date
var LastPPend		: A50 	//define Last Payperiod End Date
var LastPPpaydate	: A50 	//define pay day for last pay period
var PrintType		: A3 	//define type of receipt to print
var Date1			: A50 	//define date range - start date
var Date2			: A50 	//define date range - end date
var Date			: A10 	//define date - current report date
var query			: A1024 //define query string for each query
var strResponse		: A500  //define results of queries - not used
var result			: A256  //define results - not used
var rec_count		: N9 =0 //not used

var TipOutEmp[99]	: A50  	//define array of tip out employees
var TipOutEmpName[99] : A50 //define array of tip out employee names
var TipOutAmt[99]	: A6   	//define array of tip out amounts
var TipOutDate[99]	: A10	//define array of tips out dates

var TipRecFrom[99]	: A50 	//define array of employee (numbers) that paid tips to current employee
var TipRecFromName[99] : A50 //define array of employee names that paid tips to current employee
var TipRecAmt[99]	: A7  	//define array of tips received from other employees
var TipRecDate[99]	: A10 	//define array of date for tips received from other employees

var Last7Dates[7]	: A50  	//define dates for last 7 shifts
var Last7Shifts[7] 	: A50  	//define shift numbers for last 7 shifts

var TotalGross		: A12  	//define gross charge tips string
var TotalGrossAmt	: $12 	//define gross charge tips $
var TotalNet		: A12 	//define net charge tips string
var TotalNetAmt		: $7 	//define net charge tips $
var TotalTipOut		: A12 	//define total tips paid out string
var TotalTipOutAmt	: $12 	//define total tips paid out $
var TotalRec		: A12 	//define total tips received
var TotalRecAmt		: $12 	//define total tips received $
var CashDeclared	: A12 	//define cash declared string
var CashDeclaredAmt	: $12 	//define cash declared $
var TotalDeclared	: A12 	//define total tips declared for payroll string
var TotalDeclaredAmt : $12 	//define total declared $
var Err				: N1 	//not used
var StrErr			: A50 	//not used
var i				: N2 	//used for array
var x				: N2 	//used for array

var ClockOutDate	: A20 	//used to stored last clock out date
var ClockOutStatus 	: A1 	//used to store clock out status
var Indirect		: A1  	//used to stored current job tip type
var Tipped			: A1 	//used to store tipped status
var serverIP		: A12 	//server IP address
var mag				: A15

//retainglobalvar


//EVENTS
//______________________________________________________________________

Event inq: 35
	empPW = ""
	input empPW{M2,1,4,15}, "Please Enter ID"
	infomessage empPW
endevent


//////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------
// PRINT RECEIPT FROM CURRENT SHIFT TIPS
// ------------------------------------------------------
Event inq: 1


	if @Tremp > ""
		EmpNumber = @Tremp
	else
		//call GetEmployeeSignIn
	endif
	
	call getBusDate
	Date1 = Date
	Date2 = Date
	call Get_Emp_Seq	
	call GetTipsPaid
	call getpayrollperioddates
	printtype = "cur"
	call PrintReceipt
EndEvent
//__________________________________________________________________


//////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------
// PRINT RECEIPT FROM PREVIOUS DAY
// ------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////
Event inq: 2

	if @Tremp > ""
		EmpNumber = @Tremp
	else
		call GetEmployeeSignIn
	endif
	
	call getBusDate
	call Get_Emp_Seq	
	call GetLastDate
	call GetTipsPaid

	Date = Date1
	call getpayrollperioddates
	printtype = "cur"
	call PrintReceipt
EndEvent
//__________________________________________________________________


//////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------
// PRINT RECEIPT FROM CURRENT PAY PERIOD
// ------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////
Event inq: 3


	if @Tremp > ""
		EmpNumber = @Tremp
	else
		call GetEmployeeSignIn
	endif
	printtype = "cur"
	call getBusDate
	Call GetPayrollPeriodDates
	Date1 = curPPstart
	Date2 = curPPend
	call Get_Emp_Seq	
	call GetTipsPaid
	call PrintReceipt
EndEvent
//__________________________________________________________________


//////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------
// PRINT RECEIPT FROM LAST PAY PERIOD
// ------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////
Event inq: 4

	if @Tremp > ""
		EmpNumber = @Tremp
	else
		call GetEmployeeSignIn
	endif
	printtype = "lst"
	call getBusDate
	Call GetPayrollPeriodDates
	Date1 = lastPPstart
	Date2 = lastPPend
	call Get_Emp_Seq	
	call GetTipsPaid
	
	call PrintReceipt
EndEvent
//__________________________________________________________________


//////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------
// Display last 7 shifts and prompt to select date
// ------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////
Event inq: 5

	if @Tremp > ""
		EmpNumber = @Tremp
	endif
	call Get_Emp_Seq
	
	call getlast7shifts
	touchscreen 203
	window 9,60
	//i = 1
	for i = 1 to 7
		display i,2,i
		display i, 4,last7dates[i]
		display i,25,last7shifts[i]
	endfor
	input x,"Select Date"
	if x > 7
		exitwitherror "please select a date 1-7"
	endif 
	Date1 = last7dates[x]
	Date2 = last7dates[x]
	call GetTipsPaid
	Date = Date1
	call getPayrollPeriodDates
	printtype = "cur"
	call PrintReceipt
EndEvent
//__________________________________________________________________
//////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------
// PRINT RECEIPT FROM CURRENT SHIFT TIP OUTS
// ------------------------------------------------------
Event inq: 6


	if @Tremp > ""
		EmpNumber = @Tremp
	else
		//call GetEmployeeSignIn
	endif
	
	call getBusDate
	//Date1 = Date
	//Date2 = Date
	call Get_Emp_Seq	
	call GetShiftTipOuts
	call getpayrollperioddates
	call PrintTipOuts
EndEvent
//__________________________________________________________________
//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------
// SIGN IN SECURITY (sign-in event to catch manually entered IDs using keyboard)
// ------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////
Event SignIn
//if magsecurity = "s"
//	magsecurity = ""
//	exitcontinue
//else
//	if @WSType = 3
//		call GetSeqFromOBJ
//		if len(empPW) > 9
//			loadkybdmacro key(1,458755)
//			infomessage "please sign in first"
//		endif
//	endif
//endif
endevent
//////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------
// SIGN IN SECURITY (manual sign in)
// ------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////	
Event Inq: 75
	magsecurity = ""
	empPW = ""
	touchscreen 204
	input empPW{M2,1,4,*}, "Please Enter ID"
	empPW = trim(empPW)
	//format magsecurity as "&:<>",empPW,"?"
	//format mag as ":<>",empPW
	//LoadMagInfo mag
    //LoadKybdMacro key(1,278528)
    

		if @MAGSTATUS = "Y"
			LoadKybdMacro makekeys(emppw), key(1,65549)
			magSecurity = "s"
			
		elseif len(empPW) < 10
			LoadKybdMacro makekeys(emppw), key(1,65549)
			magSecurity = "s"
			
		elseif empPW = "2065551122"
			LoadKybdMacro makekeys(emppw), key(1,65549)
			magSecurity = "s"

		elseif @WSType = 1
			LoadKybdMacro makekeys(emppw), key(1,65549)
			magSecurity = "s"
			
		else
			if len(empPW) > 9 
				exitwitherror "Mag Card Required"
			else
				exitwitherror "Invalid ID entered"
			endif
		endif
	
EndEvent
		

//////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------
// Clock In
// ------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////
Event inq: 21

	mag = ""
	touchscreen 204
	input empPW{M2,1,4,15}, "Please Enter ID"
	if @MAGSTATUS = "Y"
		mag = "c"
	else
		mag = ""
	endif
	if mag = ""
		if @WSType = 3
			if len(empPW) > 9
				exitwitherror "Mag Card Required"
			endif
		endif
	endif
	call GetSeqfromPW
	call GetClockStatus
	if trim(ClockOutStatus) = "F"
		exitwitherror "Already Clocked In"
	else
		call ClockIn
	endif
	
EndEvent
//__________________________________________________________________

//////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------
// Go On Break
// ------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////
Event inq: 22
	mag = ""
	touchscreen 204
	input empPW{M2,1,4,15}, "Please Enter ID"
	if @MAGSTATUS = "Y"
		mag = "c"
	endif
	if mag = ""
		if @WSType = 3
			if @WSType = 3
				if len(empPW) > 9
					exitwitherror "Mag Card Required"
				endif
			endif
		endif
	endif
	call GetSeqfromPW
	call GetClockStatus
	if trim(ClockOutStatus) = "F"
		call TakeBreak
	elseif trim(ClockOutStatus) = "B"
		exitwitherror "Already on Break"
	else
		exitwitherror "Not Clocked In"
	endif

EndEvent
//__________________________________________________________________

//////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------
// Clock Out
// this event will check to see if employee is tippped before allowing clock out
// if tipped, it then checks to see if the employee is directly tipped or indirectly tipped
// directly tipped will then check for balancing between total tips paid and custom tip table
//    if they don't match, then the sim will exit with error and open the tips application
// ------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////////////////
Event inq: 23
	mag = ""
	touchscreen 204
	input empPW{M2,1,4,*}, "Please Enter ID"
	if @MAGSTATUS = "Y"
		mag = "c"
	endif
	if mag = ""
		if @WSType = 3
			if len(empPW) > 9
				exitwitherror "Mag Card Required"
			endif
		endif
	endif
	call GetSeqfromPW
	call GetClockStatus
	if trim(ClockOutStatus) = "F"
		if trim(Tipped) = "F"
			call ClockOut
			exitcontinue
		endif
		
		if Indirect = "3"
			call launchTipsWait
			call ClockOut
			exitcontinue
		else
			call posttotals
			call getshifttotals
			//debug section - remove comment // to see tip totals on screen
			//window 3,50
			//display 1,1, totalnetamt
			//display 2,1, totalgrossamt
			//display 3,1, "Press clear to continue"
			//waitforclear
			call launchTipswait
			call GetShiftTotals
			call getBusDate
			Date1 = Date
			Date2 = Date
			
			if TotalNetAmt = TotalGrossAmt
				if Indirect = "1"
					call GetTipsPaid
					call PrintReceipt
					call PrintTipOuts
				endif
				call ClockOut
			else
				errormessage "Tips not paid"
				call launchTipswait
				call GetShiftTotals
				if TotalNetAmt = TotalGrossAmt
					if Indirect = "1"
						call GetTipsPaid
						call PrintReceipt
						call PrintTipOuts
					endif
					call ClockOut
				else 
					errormessage "Tips not paid"
					call launchTipswait
					call GetShiftTotals
					if TotalNetAmt = TotalGrossAmt
						if Indirect = "1"
							call GetTipsPaid
							call PrintReceipt
							call PrintTipOuts
						endif
						call clockout
					else
						errormessage "Tips still do not balance - you have not clocked out!"
					endif
				endif
			endif
		endif
	else	
		exitwitherror "Not Clocked In"
	endif
	
EndEvent
//__________________________________________________________________



//////////////////////////////////////////////////////////////////////////////////////////////
//launch tip out application
//////////////////////////////////////////////////////////////////////////////////////////////

Event inq: 50
call postTotals
EmpNumber = @Tremp
call Get_Emp_Seq
call getserverip
//call PostTotals

	// ------ Load the SIMODBC.dll --------------------------------------
	var TipLaunch		  : n20 = 0
	//Var DLLname		      : A1024 = "\cf\micros\etc\TipLaunch.dll"
	//var dllname : a1024 = "d:\micros\res\pos\bin\tiplaunch.dll"
	Var ceExeFilename  : A1024 = ""
	var exeParams		  : A1024 = ""
	var dllResult		      :	A1024 = ""
	

	if TipLaunch = 0
		DLLLoad TipLaunch, "TipLaunch.dll"
		
	endif
	
	if TipLaunch = 0
		infomessage "Unable to Load TipLaunch.dll"
	else
		//infomessage "TipLaunch.dll successfully loaded!"
	endif


EmpSeq = trim(EmpSeq)
serverIP = trim(serverIP)

format exeParams as "http://",serverIP,"/tips/home.aspx?emp_seq=",EmpSeq
//infomessage exeParams

//for CE client
DLLCALL TipLaunch, CallExeAndWait("iesample.exe",exeParams, ref dllResult)

//for Win32 client
//DLLCALL TipLaunch, CallExeAndWait("iexplorer.exe",exeParams, ref dllResult)
//infomessage "Did it work?"

	If dllResult > -1
	   Result = dllResult
	ElseIf dllResult = -1
	   ExitWithError "Undetermined error in _ListDisplay.exe"
	ElseIf dllResult = -2
	   ExitWithError "Could not open List Data File"
	ElseIf dllResult = -3
	   ExitWithError "Error in Dll"
	ElseIf dllResult = -4
	   ExitWithError "No params supplied to _ListDisplay.exe"
	ElseIf dllResult = -5
	   ExitWithError "_ListDisplay had an unknown error"
	ElseIf dllResult = -7
	   ExitWithError "Error returned from GetExitCodeProcess in dll"
	ElseIf dllResult = -9
	   ExitWithError "Dll could not create process for supplied Exe name"
	EndIf


EndEvent
//__________________________________________________________________




//////////////////////////////////////////////////////////////////////////////////////////////
//
//									SUB ROUTINES
//
////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////
sub launchTipswait
	call getserverip

	// ------ Load the SIMODBC.dll --------------------------------------
	var TipLaunch		  : n20 = 0
	//Var DLLname		      : A1024 = "\cf\micros\etc\TipLaunch.dll"
	//var dllname : a1024 = "d:\micros\res\pos\bin\tiplaunch.dll"
	Var ceExeFilename  : A1024 = ""
	var exeParams		  : A1024 = ""
	var dllResult		      :	A1024 = ""
	

	if TipLaunch = 0
		DLLLoad TipLaunch, "TipLaunch.dll"
		
	endif
	
	if TipLaunch = 0
		infomessage "Unable to Load TipLaunch.dll"
	else
		//infomessage "TipLaunch.dll successfully loaded!"
	endif


EmpSeq = trim(EmpSeq)
serverIP = trim(serverIP)

format exeParams as "http://",serverIP,"/tips/home.aspx?emp_seq=",EmpSeq


//for CE client
DLLCALL TipLaunch, CallExeAndWait("iesample.exe",exeParams, ref dllResult)



	If dllResult > -1
	   Result = dllResult
	ElseIf dllResult = -1
	   ExitWithError "Undetermined error in _ListDisplay.exe"
	ElseIf dllResult = -2
	   ExitWithError "Could not open List Data File"
	ElseIf dllResult = -3
	   ExitWithError "Error in Dll"
	ElseIf dllResult = -4
	   ExitWithError "No params supplied to _ListDisplay.exe"
	ElseIf dllResult = -5
	   ExitWithError "_ListDisplay had an unknown error"
	ElseIf dllResult = -7
	   ExitWithError "Error returned from GetExitCodeProcess in dll"
	ElseIf dllResult = -9
	   ExitWithError "Dll could not create process for supplied Exe name"
	EndIf


endsub
//////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////
sub ClockIn
	loadKybdMacro key (1,655368)
	loadKybdMacro makekeys (empPW)
	loadKybdMacro key (1, 65549)	
endsub
//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////
sub TakeBreak
		loadKybdMacro key (1,655368)
		loadKybdMacro makekeys (empPW)
		loadKybdMacro key (1, 65549)	
		loadKybdMacro key (1, 65549)	
		loadKybdMacro key (1, 65549)	
endsub
//////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////
sub ClockOut
		loadKybdMacro key (1,655368)
		loadKybdMacro makekeys (empPW)
		loadKybdMacro key (1, 65549)	
		loadKybdMacro key (1, 65549)	
		loadKybdMacro key (1,65548)
endsub
//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////
sub getBusDate
		//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		
		if constatus = 0
		DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		
		Format query as "select date(business_date) as bDate from micros.rest_status"

		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)

		split query, ";", Date
		
		DllFree hODBCDLL
endsub
//////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////
sub getPayrollPeriodDates
		//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)

		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		

		Format query as "CALL custom.cstm_GetPayPeriod(p_date = '",Date,"')"

		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)

		split query, ";", curPPstart, curPPend, lastPPstart, lastPPend
		
		Format query as "select date(dateadd(day,7,'",curPPstart,"')) as LastPPpaydate, date(dateadd(day,8,'",curPPend,"')) as CurPPpaydate"

		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)

		split query, ";",LastPPpaydate, CurPPpaydate
		DllFree hODBCDLL

endsub
//////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////
//
sub GetTipsPaid
//
//for printing receipts
////////////////////////////////////////////////////////////////////////////////////////////////
	
//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		
		if constatus = 0
		
		DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		

	//get charge tips paid out for date range
		cleararray TipOutEmp
		cleararray TipOutAmt
		cleararray TipOutEmpName
		query = ""
		Format query as "select x.empseq, sum(x.chrgtips), x.empname, date(x.businessdate) as bDate, x.shift as shiftNumber from (select c.emp_seq as empSeq, c.chrg_tips as ChrgTips, m.first_name+' '+m.last_name as empName, businessdate, c.parent_shift_number as shift from custom.cstm_emp_tips c inner join micros.emp_def m on c.emp_seq = m.emp_seq where parent_seq = ",EmpSeq," and c.emp_seq <> ",EmpSeq," and businessdate between '",Date1,"' and '",Date2,"' and ispool < 1 and chrg_tips > 0 union all select c.emp_seq as empSeq, c.chrg_tips as ChrgTips, p.poolname as empName, businessdate, c.parent_shift_number as shift from custom.cstm_emp_tips c inner join custom.cstm_pool_list p on c.emp_seq = p.poolid where parent_seq = ",EmpSeq," and c.emp_seq <> ",EmpSeq," and businessdate between '",Date1,"' and '",Date2,"' and ispool = 1 and chrg_tips > 0) x group by shiftNumber, empseq, empname, businessdate order by businessdate"
	
		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
		if len(query) < 1 then
			format strErr as "No Tips Received"
		
		else
			split query, ";", TipOutEmp[1], TipOutAmt[1], TipOutEmpName[1], TipOutDate[1]
			Mid (TipOutDate[1], 1, 5) = "     "
			TipOutDate[1] = trim(TipOutDate[1])
			i =1
			while len(query) > 1
				DLLCALL_CDECL hODBCDLL, sqlGetNext(ref query)
				if len(query) > 1
					i = i+1
					split query, ";",TipOutEmp[i], TipOutAmt[i], TipOutEmpName[i], TipOutDate[i]
					Mid (TipOutDate[i], 1, 5) = "     "
					TipOutDate[i] = trim(TipOutDate[i])
				endif
			endwhile
		endif

	//get charge tips received for date range
		cleararray TipRecFrom
		cleararray TipRecAmt
		cleararray TipRecFromName
		cleararray TipRecDate
		query = ""
		Format query as "select x.empseq, sum(x.chrgtips),x.empname, date(x.businessdate) as bDate, x.shift as shiftNumber from ( select c.parent_seq as empSeq, c.chrg_tips as ChrgTips, m.first_name+' '+m.last_name as empName, businessdate, c.parent_shift_number as shift from custom.cstm_emp_tips c inner join micros.emp_def m on c.parent_seq = m.emp_seq where c.emp_seq = ",EmpSeq," and c.parent_seq <> ",EmpSeq," and c.parent_seq > 0 and businessdate between '",Date1,"' and '",Date2,"' and chrg_tips > 0 union all select c.parent_seq as empSeq, c.chrg_tips as ChrgTips, p.poolname as empName, businessdate, c.parent_shift_number from custom.cstm_emp_tips c inner join custom.cstm_pool_list p on c.parent_seq = p.poolid where emp_seq = ",EmpSeq," and c.parent_seq <> ",EmpSeq," and c.parent_seq < 0 and businessdate between '",Date1,"' and '",Date2,"' and chrg_tips > 0) x group by shiftNumber, empseq, empname, businessdate order by businessdate"

		
		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
		
		if len(query) < 1 then
			format strErr as "No Tips Paid Out"
		
		else
			split query, ";", TipRecFrom[1], TipRecAmt[1], TipRecFromName[1], TipRecDate[1]
			Mid (TipRecDate[1], 1, 5) = "     "
			TipRecDate[1] = trim(TipRecDate[1])
			i =1
			while len(query) > 1

				DLLCALL_CDECL hODBCDLL, sqlGetNext(ref query)
				if len(query) > 1
				i = i+1	
					split query, ";",TipRecFrom[i], TipRecAmt[i], TipRecFromName[i], TipRecDate[i]
					Mid (TipRecDate[i], 1, 5) = "     "
					TipRecDate[i] = trim(TipRecDate[i]	)				
				endif
			endwhile
		endif
	
	//get tip totals for date range
		
		query = ""
		Format query as "select sum(parent_old_tips/2) as gross, sum(decl_cash/2) as cash from custom.cstm_emp_tips where emp_seq = ",EmpSeq," and parent_seq = ",EmpSeq," and businessdate between '",Date1,"' and '",Date2,"'"
		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
		if len(query) < 1 then
			format strErr as "No Tips"
		else
			split query, ";", TotalGross, CashDeclared
			TotalGrossAmt = TotalGross
			CashDeclaredAmt = CashDeclared
		endif

	//get total charge tips received for date range
		query = ""
		format query as "select sum(chrg_tips) from custom.cstm_emp_tips where emp_seq = ",EmpSeq," and businessdate between '",Date1,"' and '",Date2,"'"

		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
		if len(query) < 1 then
			format strErr as "No Tips"
			
		else
			TotalNetAmt = query
			TotalDeclaredAmt = TotalNetAmt + CashDeclaredAmt

		
		endif
		
		

	//get total tips paid out
		query = ""
		format query as "select sum(chrg_tips) from custom.cstm_emp_tips where parent_seq = ",EmpSeq," and emp_seq <> ",EmpSeq," and businessdate between '",Date1,"' and '",Date2,"'"

		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)

		if len(query) < 1 then
			format strErr as "No Tips"
		else
			TotalTipOutAmt = query
			
	//get total tips received
		query = ""
		format query as "select sum(chrg_tips) from custom.cstm_emp_tips where emp_seq = ",EmpSeq," and parent_seq <> ",EmpSeq," and businessdate between '",Date1,"' and '",Date2,"'"

		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)

		if len(query) < 1 then
			format strErr as "No Tips"
		else
			TotalRecAmt = query


		endif
	DllFree hODBCDLL
endsub	
//////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////////////////////////////
sub GetShiftTipOuts
//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		
		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		
//get tips paid out for shift
		cleararray TipOutEmp
		cleararray TipOutAmt
		cleararray TipOutEmpName
		query = ""
		Format query as "select x.empseq, sum(x.chrgtips), x.empname from (select c.emp_seq as empSeq, c.chrg_tips as ChrgTips, m.first_name+' '+m.last_name as empName from custom.cstm_emp_tips c inner join micros.emp_def m on c.emp_seq = m.emp_seq where parent_seq = ",EmpSeq," and c.emp_seq <> ",EmpSeq," and businessdate = '",Date,"'  and ispool < 1 and parent_shift_number = ",ShiftNum," union select c.emp_seq as empSeq, c.chrg_tips as ChrgTips, p.poolname as empName from custom.cstm_emp_tips c inner join custom.cstm_pool_list p on c.emp_seq = p.poolid where parent_seq = ",EmpSeq," and c.emp_seq <> ",EmpSeq,"  and parent_shift_number = ",ShiftNum," and businessdate = '",Date,"' ) x group by empseq, empname"
	
		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
		if len(query) < 1 then
			format strErr as "No Tips Received"
		
		else
			split query, ";", TipOutEmp[1], TipOutAmt[1], TipOutEmpName[1]
			i =1
			while len(query) > 1
				DLLCALL_CDECL hODBCDLL, sqlGetNext(ref query)
				if len(query) > 1
					i = i+1
					split query, ";",TipOutEmp[i], TipOutAmt[i], TipOutEmpName[i]
				endif
			endwhile
		endif
endsub
//////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////////////////////////////
sub GetShiftTotals
//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		
		if constatus = 0
				DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		
		Format query as "select tips_paid_ttl from micros.shift_emp_ttl where emp_seq = ",EmpSeq," and shift_seq = (select max(shift_seq) from micros.shift_emp_dtl where emp_seq = ",EmpSeq," and date(shift_start_time) = (select max(labor_date) from micros.time_card_dtl))"
		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
			
		if len(query) < 1 then
			format strErr as "No Tips"
			TotalGrossAmt = 0
		else
			split query, ";", TotalGross
			TotalGrossAmt = TotalGross
		endif
		
		
		Format query as "select isnull(sum(chrg_tips),0) from custom.cstm_emp_tips where parent_seq = ",EmpSeq," and parent_shift_number = (select max(shift_seq) from micros.shift_emp_dtl where emp_seq = ",EmpSeq," and date(shift_start_time) = (select max(labor_date) from micros.time_card_dtl))"
		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
		if len(query) < 1 then
			format strErr as "No Tips"
			TotalNetAmt = 0
		else
			split query, ";", TotalNet
			TotalNetAmt = TotalNet
		endif
		
		 
	DllFree hODBCDLL
endsub	
//////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////
           sub GetLast7Shifts
//for printing receipts
////////////////////////////////////////////////////////////////////////////////////////////////
//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		
		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		

		Format query as "select distinct(date(c.businessdate)), j.name from custom.cstm_emp_tips c inner join micros.job_def j on c.job_seq=j.job_seq where c.emp_seq = ",EmpSeq," order by 1 desc"
	
		DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
		DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
			
		if len(query) < 1 then
			format strErr as "No Previous Shifts"
			exitwitherror strErr
		
		else
			split query, ";", last7dates[1], last7shifts[1]
//			infomessage last7dates[1]
			for i = 2 to 7				
				DLLCALL_CDECL hODBCDLL, sqlGetNext(ref query)
				split query, ";",last7dates[i], last7shifts[i]
			endfor
		endif
endsub
//////////////////////////////////////////////////////////////////////////////////////////////
		
		
//////////////////////////////////////////////////////////////////////////////////////////////
sub displaydata
//debug section for checking variables
	window 10, 50
	display 1, 2, EmpName
	display 2, 2, Date
	x = 3
	i = 1
		while len(tipoutemp[i]) > 0
			display x, 2, TipOutEmp[i]
			display x, 25, TipOutAmt[i]
			i = i+1
			x = x+1
		endwhile
	waitforclear
endsub
//////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////
sub PrintReceipt
		StartPrint @Chk
			PrintLine "           Tip Detail Report"
			PrintLine EmpName
			PrintLine "Today's Date: ",Date
			PrintLine "___________________________________"
			PrintLine "       Report Date Range:"
			PrintLine Date1, " through ",Date2
			PrintLine "___________________________________"
			if printtype = "cur"
				PrintLine "PayDate: ",curPPpaydate
			elseif printtype = "lst"
				PrintLine "Paydate: ",lastPPpaydate
			endif
			PrintLine "___________________________________"
			if len(tipoutemp[1])>0
				PrintLine "Charge Tips Paid Out:"
			endif
				i = 1
				while len(tipoutemp[i]) > 0
					PrintLine TipOutDate[i]," - ",TipOutEmpName[i], " - $", TipOutAmt[i]
					i = i+1
				endwhile
			PrintLine "___________________________________"
			if len(TipRecFrom[1])>0
				PrintLine "Charge Tips Received From Others:"
			endif
				i = 1 
				while len(TipRecFrom[i]) > 0
					PrintLine TipRecDate[i]," - ",TipRecFromName[i], " - $", TipRecAmt[i]
					i = i+1
				endwhile
			PrintLine "___________________________________"
			PrintLine "Gross Charge Tips:         $", TotalGrossAmt{>}
			PrintLine "Charge Tips Received:      $",TotalRecAmt{>}
			PrintLine "Charge Tip Out Total:     -$", TotalTipOutAmt{>}
			PrintLine "NET CHARGE TIPS (Payroll): $",TotalNetAmt{>}
			PrintLIne "Cash Tips Declared:        $",CashDeclaredAmt{>}
			PrintLine "Total Tips Declared:       $",TotalDeclaredAmt{>}
			PrintLine "___________________________________"
		Endprint
		//loadkybdmacro key(10, 903)

	   endif
endsub	
//////////////////////////////////////////////////////////////////////////////////////////////
         

//////////////////////////////////////////////////////////////////////////////////////////////
sub PrintTipOuts
		StartPrint @Chk
			PrintLine "       Tips Paid Receipt"
			PrintLine EmpName
			PrintLine "Today's Date: ",Date
			PrintLine "___________________________________"
			PrintLine "Charge Tips Paid Out: "
			PrintLine ""
				i = 1
				while len(tipoutemp[i]) > 0
					PrintLine "   ",TipOutEmpName[i], "  ", TipOutAmt[i]{>}
					i = i+1
				endwhile
			PrintLine "___________________________________"
			PrintLine "Write Tip Outs Paid in Cash:"
			PrintLine ""
			PrintLine "___________________________________"
			PrintLine ""
			PrintLine "___________________________________"
			PrintLine ""
			PrintLine "___________________________________"
			PrintLine ""
			PrintLine "___________________________________"
		Endprint
	   endif
endsub	
//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////
Sub Get_Emp_Seq
	
//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		
		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		

	//  ------Query to get emp_seq
	format query as "SELECT emp_seq from micros.emp_def WHERE obj_num = ", EmpNumber

	DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
	DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
	format EmpSeq as query
	split EmpSeq, ";" , EmpSeq
	
	//  -----Query to get shift_number
	
	format query as "SELECT max(shift_number) from custom.cstm_emp_tips where parent_seq = ",EmpSeq," and businessdate between '",Date,"' and '",Date,"'"
	DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
	DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
	format ShiftNum as query
	split ShiftNum, ";", ShiftNum
	
	//  ----Query to get Name
	format query as "select first_name+' '+last_name as Name from micros.emp_def where emp_seq =",empseq
	DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
	DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
	split query,";",EmpName
		
	DllFree hODBCDLL	
EndSub
//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////
sub GetSeqFromOBJ
	
//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		
		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		
	call getBusDate
	

	//  ------Query to get emp_seq
	format query as "SELECT emp_seq, id from micros.emp_def WHERE obj_num = ", @Tremp


	DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
	DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
	if len(query) < 1
		exitwitherror "ERROR: Invalid ID"
	else
		split query, ";" , EmpSeq,EmpPW
	endif
	DllFree hODBCDLL
endSub
//////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////////////////////////////
sub GetSeqFromPW
	
//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		
		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		
	call getBusDate
	

	//  ------Query to get emp_seq
	format query as "SELECT emp_seq from micros.emp_def WHERE id = ", empPW

	DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
	DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
	if len(query) < 1
		exitwitherror "ERROR: Invalid ID"
	else
		split query, ";" , EmpSeq
	endif
	format query as "SELECT max(shift_seq) from micros.shift_emp_ttl where shift_start_time between '",date,"' and dateadd(day,1,'",date,"') and emp_seq=",EmpSeq
	DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
	DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
	split query, ";", ShiftNum
	DllFree hODBCDLL
endSub
//////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////
sub GetLastDate

//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		
		if constatus = 0
				DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		
	//  ------Query to get emp_seq
	format query as "SELECT distinct(date(businessdate)) from custom.cstm_emp_tips where emp_seq = ",EmpSeq," order by 1 desc"

	DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
	DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
		if len(query) < 1 then
			format strErr as "No Records"
			Date1 = Date
		else
			split query, ";", Date1

		endif
	DLLCALL_CDECL hODBCDLL, sqlGetNext(ref query)
	if len(query) < 1 then
		format strErr as "No Records"
		//Date1 = Date
	else
		split query, ";",Date1

	endif
	Date2 = Date1

	DllFree hODBCDLL

endsub
//////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////
sub getClockStatus

//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		
		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		

	format query as "select date(isnull(clk_out_date_tm,'2000-1-1')) as ClockOutDate, isnull(clk_out_status,'F') as ClockOutStatus, j.lab_cat as Category, j.ob_tipped as Tipped from micros.time_card_dtl t left join micros.job_def j on t.job_seq=j.job_seq where emp_seq = ",EmpSeq," and clk_in_date_tm = (select max(clk_in_date_tm) from micros.time_card_dtl where emp_seq = ",EmpSeq,")"
	DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
	DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
		if len(query) < 1 then
			format strErr as "No Records"
		else
			split query, ";", clockOutDate, ClockOutStatus, Indirect, Tipped
		endif

	DllFree hODBCDLL
endsub
//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////
sub GetServerIP

//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		
	//  ------Query to get emp_seq
	format query as "select ip_addr from micros.lan_node_def where obj_num = 99"

	DLLCALL_CDECL hODBCDLL, sqlGetRecordSet(query)
	DLLCALL_CDECL hODBCDLL, sqlGetFirst(ref query)
		if len(query) < 1 then
			format strErr as "No Records"
		else
			split query, ";", serverIP
		endif
	
	DllFree hODBCDLL
endsub
//////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////////////////
sub PostTotals

//---------------------------------------------------------------------------		
		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
			DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
			exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
//---------------------------------------------------------------------------		
	//  ------SP to post totals
	
	//format query as "CALL micros.sp_R_employee_sales_tracking"
	//DLLCALL_CDECL hODBCDLL, sqlExecuteQuery(query)

	//format query as "call micros.sp_P_employee_sales_tracking( )"
	//DLLCALL_CDECL hODBCDLL, sqlExecuteQuery(query)

	//postAll is working but need to isolate the postings in postall that are actually needed.	
	format query as "Call micros.sp_PostAll()"
	DLLCALL_CDECL hODBCDLL, sqlExecuteQuery(query)
	DllFree hODBCDLL

endsub
//////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////////////////////////////
// ------ Load DataBase --------------------------------------not used (error on WS5)
//////////////////////////////////////////////////////////////////////////////////////////////		

sub LoadDB

		var hODBCDLL      : N20 = 0
		var constatus        : N9	
		if hODBCDLL = 0
		DLLLoad hODBCDLL, "MDSSysUtilsProxy.dll"
		endif
		if hODBCDLL = 0
		exitwitherror "Unable to Load MDSSysUtilsProxy.dll"
		else
		//infomessage "MDSSysUtilsProxy.dll successfully loaded!"
		endif

		// ------ Connect to the database

		DLLCALL_CDECL hODBCDLL, sqlIsConnectionOpen(ref constatus)
		if constatus = 0
			DLLCALL_CDECL hODBCDLL, sqlInitConnection("micros","ODBC;UID=custom;PWD=custom", "")
		endif
endSub
//////////////////////////////////////////////////////////////////////////////////////////////		


