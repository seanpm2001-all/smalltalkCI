''!
Object subclass: #MetacelloBuilderTravisCI
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'TravisCI'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MetacelloBuilderTravisCI class
	instanceVariableNames: ''!

!MetacelloBuilderTravisCI class methodsFor: 'git' stamp: 'dkh 9/4/2012 18:36'!
gitPath
    ^ self gitPathFor: 'git_cache'! !

!MetacelloBuilderTravisCI class methodsFor: 'git' stamp: 'dkh 9/4/2012 18:33'!
gitPathFor: gitCacheName
    ^ (Smalltalk at: #'FileDirectory' ifAbsent: [  ])
        ifNil: [ 
            "Pharo-2.x"
            (((Smalltalk at: #'FileSystem') perform: #workingDirectory) / gitCacheName) pathString ]
        ifNotNil: [ :fileDirectoryClass | 
            "Pharo-1.x"
            (fileDirectoryClass default directoryNamed: gitCacheName) fullName ]! !


!MetacelloBuilderTravisCI class methodsFor: 'retry' stamp: 'dkh 9/4/2012 18:28'!
retry: aBlock
    self retry: aBlock retryCount: 3! !

!MetacelloBuilderTravisCI class methodsFor: 'retry' stamp: 'dkh 9/4/2012 18:28'!
retry: aBlock retryCount: retryCount
    | count |
    count := 1.
    [ true ]
        whileTrue: [ 
            [ 
            aBlock value.
            ^ self ]
                on: Error
                do: [ :ex | 
                    count < retryCount
                        ifTrue: [ 
                            Transcript
                                cr;
                                show: 'RETRYING AFTER:';
                                cr;
                                show: ex description printString.
                            (Delay forSeconds: 10) wait.]
                        ifFalse: [ 
                            Transcript
                                cr;
                                show: 'FAILED RETRYING:';
                                cr;
                                show: ex description printString.
                            ex pass ] ].
            count := count + 1 ]! !


!MetacelloBuilderTravisCI class methodsFor: 'test harness' stamp: 'dkh 9/4/2012 18:31'!
runHarnessFor: configurationClassNameList exclude: categoryListString exclude: classListString
    | suite categoryList classList |
    suite := TestCase suiteClass named: configurationClassNameList printString , ' Test Suite'.
    categoryList := categoryListString subStrings: ','.
    classList := classListString subStrings: ','.
    configurationClassNameList
        do: [ :className | 
            (((Smalltalk at: #'MetacelloProjectRegistration')
                registrationForClassNamed: className
                ifAbsent: [ self error: className printString , ' not registered (loaded)' ])
                currentlyLoadedClassesInProject select: [ :cl | (cl inheritsFrom: TestCase) and: [
                    ((categoryList anySatisfy: [ :ex | cl category asString startsWith: ex ]) or: [
                        classList anySatisfy: [ :ex | ex = cl name ] ]) not] ])
                do: [ :cl | 
                    cl isAbstract
                        ifFalse: [ suite addTest: cl buildSuiteFromSelectors ] ] ].
    self runTestSuite: suite! !

!MetacelloBuilderTravisCI class methodsFor: 'test harness' stamp: 'dkh 11/20/2014 15:56'!
runTestSuite: suite
    [ 
    | result |
    result := suite run.
    Transcript cr;
        show: '**************************************************************************************'; cr;
        show: 'Results for ', suite name; cr;
        show: result printString; cr;
        show: '**************************************************************************************'; cr.

    result failures notEmpty
        ifTrue: [ 
            Smalltalk at: #travisCIExitCode put: 1.
            Transcript
                show: '*** FAILURES *************************************************************************'; cr;
                show: '**************************************************************************************'; cr ].
    result failures
        do: [ :each | 
            | errMsg |
            "Re-run test case and collect debug info"
            [ each performTest ] on: Exception do: [ :signal |
                errMsg := signal asString ].
            Transcript show: each class name asString , '>>' , each selector printString , ' (', errMsg, ')'; cr ].
    result errors notEmpty
        ifTrue: [ 
            Smalltalk at: #travisCIExitCode put: 1.
            Transcript
                show: '**** ERRORS **************************************************************************'; cr;
                show: '**************************************************************************************'; cr ].
    result errors
        do: [ :each |
            | errMsg errStack |
            "Re-run test case and collect debug info"
            [ each performTest ] on: Exception do: [ :signal |
                errMsg := signal asString.
                errStack := signal signalerContext shortStack ].
            Transcript
                show: '/*-------------------------------------------------------'; cr;
                show: each class name asString , '>>' , each selector printString , ' (', errMsg, ')';
                cr; cr;
                show: errStack;
                show: '-------------------------------------------------------*/'; cr; cr ].
    Transcript show: '**************************************************************************************']
    ensure: [ FileStream flushAndVoidStdioFiles ]! !


!MetacelloBuilderTravisCI class methodsFor: 'filein' stamp: 'dkh 9/4/2012 18:33'!
fileIn: fileName
    (Smalltalk at: #'FileDirectory' ifAbsent: [  ])
        ifNil: [ ((Smalltalk at: #'FileSystem') perform: #workingDirectory) / fileName readStreamDo: [ :fileStream | fileStream fileIn ] ]
        ifNotNil: [ :fileDirectoryClass | fileDirectoryClass default fileNamed: fileName do: [ :fileStream | fileStream fileIn ] ]! !