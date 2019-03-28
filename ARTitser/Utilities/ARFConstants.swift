//
//  ARFConstants.swift
//  ARFollow
//
//  Created by Julius Abarra on 12/10/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import Foundation
import UIKit

struct ARFConstants {
    
    struct endPoint {
        static let PRI_LOGIN_USER: String = "login/user"
        static let PRI_LOGOUT_USER: String = "logout/user/%@"
        static let STA_RETRIEVE_ADMIN_DASHBOARD_PRI: String = "retrieve/statistics/administrator/dashboard/primary/%@"
        static let STA_RETRIEVE_ACTIVITIES: String = "retrieve/activities"
        static let STA_RETRIEVE_CREATOR_DASHBOARD_PRI: String = "retrieve/statistics/creator/dashboard/primary/%@"
        static let STA_RETRIEVE_GAME_PERCENTAGE_SUCCESS: String = "retrieve/game/success/rate/user/%@"
        static let USR_CREATE_USER: String = "create/user/requestor/%@"
        static let USR_RETRIEVE_USERS: String = "retrieve/users/requestor/%@"
        static let USR_UPDATE_USER_BY_ID: String = "update/user/%@/requestor/%@"
        static let USR_DELETE_USER_BY_ID: String = "delete/user/%@/requestor/%@"
        static let USR_APPROVE_USER_BY_ID: String = "approve/user/%@/requestor/%@"
        static let CRS_CREATE_COURSE: String = "create/course/requestor/%@"
        static let CRS_RETRIEVE_COURSES: String = "retrieve/courses/requestor/%@"
        static let CRS_UPDATE_COURSE_BY_ID: String = "update/course/%@/requestor/%@"
        static let CRS_DELETE_COURSE_BY_ID: String = "delete/course/%@/requestor/%@"
        static let CLS_RETRIEVE_CLASSES: String = "retrieve/classes/requestor/%@"
        static let CLS_RETRIEVE_CLASSES_FOR_PLAYER: String = "retrieve/classes/player/%@/requestor/%@"
        static let CLS_CREATE_CLASS: String = "create/class/requestor/%@"
        static let CLS_UPDATE_CLASS_BY_ID: String = "update/class/%@/requestor/%@"
        static let CLS_DELETE_CLASS_BY_ID: String = "delete/class/%@/requestor/%@"
        static let CLU_CREATE_CLUE: String = "create/clue/requestor/%@"
        static let CLU_RETRIEVE_CLUES_CREATED_BY_USER: String = "retrieve/clues/user/%@/requestor/%@"
        static let CLU_UPDATE_CLUE_BY_ID: String = "update/clue/%@/requestor/%@"
        static let CLU_DELETE_CLUE_BY_ID: String = "delete/clue/%@/requestor/%@"
        static let TRE_CREATE_TREASURE: String = "create/treasure/requestor/%@"
        static let TRE_RETRIEVE_TREASURES_CREATED_USER: String = "retrieve/treasures/user/%@/requestor/%@"
        static let TRE_UPDATE_TREASURE_BY_ID: String = "update/treasure/%@/requestor/%@"
        static let TRE_DELETE_TREASURE_BY_ID: String = "delete/treasure/%@/requestor/%@"
        static let GAM_CREATE_GAME: String = "create/game/requestor/%@"
        static let GAM_RETRIEVE_GAMES_CREATED_BY_USER: String = "retrieve/games/user/%@/requestor/%@"
        static let GAM_RETRIEVE_GAMES_FOR_CLASS: String = "retrieve/games/class/%@/requestor/%@"
        static let GAM_UPDATE_GAME_BY_ID: String = "update/game/%@/requestor/%@"
        static let GAM_DELETE_GAME_BY_ID: String = "delete/game/%@/requestor/%@"
        static let GAM_RETRIEVE_CLASSES_FOR_DEPLOYED_GAME: String = "retrieve/classIds/game/%@/requestor/%@"
        static let GAM_DEPLOY_GAME: String = "deploy/game/%@/requestor/%@"
        static let GAM_UNDEPLOY_GAME: String = "undeploy/game/%@/requestor/%@"
        static let GAM_RETRIEVE_GAME_RESULT: String = "retrieve/game/result/%@/%@/requestor/%@"
        static let GAM_RETRIEVE_FINISHED_GAMES: String = "retrieve/games/class/%@/player/%@/requestor/%@"
        static let GAM_RETRIEVE_UNLOCKED_TREASURES: String = "/retrieve/unlocked/treasures/player/%@/requestor/%@"
        static let GAM_SUBMIT_GAME_RESULT: String = "submit/game/result/requestor/1"
        static let PLA_RETRIEVE_SIDEKICKS_FOR_PLAYER: String = "retrieve/sidekick/player/%@/requestor/%@"
        static let PLA_CREATE_SIDEKICK: String = "create/sidekick/requestor/1"
        static let PLA_RETRIEVE_PLAYERS_FOR_RANKING: String = "retrieve/players/requestor/%@"
    }
    
    struct entity {
        static let ACTIVITY: String = "Activity"
        static let USER: String = "User"
        static let COURSE: String = "Course"
        static let CLASS: String = "Class"
        static let CLASS_COURSE: String = "ClassCourse"
        static let CLASS_CREATOR: String = "ClassCreator"
        static let CLASS_PLAYER: String = "ClassPlayer"
        static let CLUE: String = "Clue"
        static let CLUE_CHOICE: String = "ClueChoice"
        static let TREASURE: String = "Treasure"
        static let FILE: String = "File"
        static let GAME: String = "Game"
        static let GAME_TREASURE: String = "GameTreasure"
        static let GAME_CLUE: String = "GameClue"
        static let GAME_CLUE_CHOICE: String = "GameClueChoice"
        static let SIDEKICK: String = "Sidekick"
        static let FINISHED_GAME: String = "FinishedGame"
        static let PLAYER_RANKING: String = "PlayerRanking"
        static let DEEP_COPY_COURSE: String = "DeepCopyCourse"
        static let DEEP_COPY_USER: String = "DeepCopyUser"
        static let DEEP_COPY_CLASS: String = "DeepCopyClass"
        static let DEEP_COPY_CLASS_COURSE: String = "DeepCopyClassCourse"
        static let DEEP_COPY_CLASS_CREATOR: String = "DeepCopyClassCreator"
        static let DEEP_COPY_CLASS_PLAYER: String = "DeepCopyClassPlayer"
        static let DEEP_COPY_CLUE: String = "DeepCopyClue"
        static let DEEP_COPY_CLUE_CHOICE: String = "DeepCopyClueChoice"
        static let DEEP_COPY_TREASURE: String = "DeepCopyTreasure"
        static let DEEP_COPY_GAME: String = "DeepCopyGame"
        static let DEEP_COPY_GAME_TREASURE: String = "DeepCopyGameTreasure"
        static let DEEP_COPY_GAME_CLUE: String = "DeepCopyGameClue"
        static let DEEP_COPY_GAME_CLUE_CHOICE: String = "DeepCopyGameClueChoice"
        static let DEEP_COPY_SIDEKICK: String = "DeepCopySidekick"
    }
    
    struct userType {
        static let GA: Int64 = 0
        static let GC: Int64 = 1
        static let GP: Int64 = 2
    }
    
    struct segueIdentifier {
        static let GAV: String = "showGAView"
        static let GCV: String = "showGCView"
        static let GPV: String = "showGPView"
        static let GAV_USER_VIEW: String = "showGAVUserView"
        static let GAV_USER_CREATION_VIEW: String = "showGAVUserCreationView"
        static let GAV_USER_DETAILS_VIEW: String = "showGAVUserDetailsView"
        static let GAV_COURSE_VIEW: String = "showGAVCourseView"
        static let GAV_CLASS_VIEW: String = "showGAVClassView"
        static let GAV_COURSE_CREATION_VIEW: String = "showGAVCourseCreationView"
        static let GAV_COURSE_DETAILS_VIEW: String = "showGAVCourseDetailsView"
        static let GAV_CLASS_CREATION_VIEW: String = "showGAVClassCreationView"
        static let GAV_CLASS_USER_SELECTION_VIEW: String = "showClassUserSelectionView"
        static let GAV_CLASS_COURSE_SELECTION_VIEW: String = "showClassCourseSelectionView"
        static let GAV_CLASS_DETAILS_VIEW: String = "showGAVClassDetailsView"
        static let GCV_CLUE_VIEW: String = "showGCVClueView"
        static let GCV_CLUE_TYPE_SELECTION_VIEW: String = "showGCVClueTypeSelectionView"
        static let GCV_CLUE_CREATION_MC_VIEW: String = "showGCVClueCreationMCView"
        static let GCV_CLUE_DETAILS_VIEW: String = "showGCVClueDetailsView"
        static let GCV_PLACE_PICKER_VIEW: String = "showGCVPlacePickerView"
        static let GCV_TREASURE_VIEW: String = "showGCVTreasureView"
        static let GCV_TREASURE_CREATION_VIEW: String = "showGCVTreasureCreationView"
        static let GCV_TREASURE_DETAILS_VIEW: String = "showGCVTreasureDetailsView"
        static let GCV_FILE_VIEW: String = "showGCVFileView"
        static let GCV_GAME_VIEW: String = "showGCVGameView"
        static let GCV_GAME_CREATION_VIEW: String = "showGCVGameCreationView"
        static let GCV_GAME_DETAILS_VIEW: String = "showGCVGameDetailsView"
        static let GCV_GAME_TREASURE_SELECTION_VIEW: String = "showGCVGameTreasureSelectionView"
        static let GCV_GAME_CLUE_SELECTION_VIEW: String = "showGCVGameClueSelectionView"
        static let GCV_GAME_CLASS_SELECTION_VIEW: String = "showGCVClassSelectionView"
        static let GCV_GAME_RESULT_VIEW: String = "showGCVGameResultView"
        static let GPV_SIDEKICK_SELECTION_VIEW: String = "showGPVSidekickSelectionView"
        static let GPV_SIDEKICK_NAMING_VIEW: String = "showGPVSidekickNamingView"
        static let GPV_SIDEKICK_WELCOME_VIEW: String = "showGPVSidekickWelcomeView"
        static let GPV_SIDEKICK_DETAILS_VIEW: String = "showGPVSidekickDetailsView"
        static let GPV_TRESURE_VIEW: String = "showGPVTreasureView"
        static let GPV_TREASURE_AR_VIEW: String = "showGPVTreasureARView"
        static let GPV_RANKING_VIEW: String = "showGPVRankingView"
        static let GPV_CLASS_VIEW: String = "showGPVClassView"
        static let GPV_CLASS_DETAILS_VIEW: String = "showGPVClassDetailsView"
        static let GPV_GAME_VIEW: String = "showGPVGameView"
        static let GPV_GAME_RESULT_VIEW: String = "showGPVGameResultView"
        static let GPV_GAME_DISCUSSION_VIEW: String = "showGPVGameDiscussionView"
        static let GPV_GAME_PLAY_VIEW: String = "showGPVGamePlayView"
        static let GPV_GAME_CLUE_VIEW: String = "showGPVGameClueView"
        static let GPV_GAME_TREASURE_VIEW: String = "showGPVGameTreasureView"
        static let GPV_GAME_PAUSE_VIEW: String = "showGPVGamePauseView"
        static let GPV_GAME_MAP_VIEW: String = "showGPVGameMapView"
        static let GPV_GAME_PLAY_RESULT_VIEW: String = "showGPVGamePlayResultView"
        static let GEN_MY_ACCOUNT_VIEW: String = "showGENMyAccountView"
    }
    
    struct cellIdentifier {
        static let USER: String = "userCellIdentifier"
        static let COURSE: String = "courseCellIdentifier"
        static let CLASS: String = "classCellIdentifier"
        static let CLUE: String = "clueCellIdentifier"
        static let TREASURE: String = "treasureCellIdentifier"
        static let FILE: String = "fileCellIdentifier"
        static let GAME: String = "gameCellIdentifier"
        static let ACTIVITY: String = "activityCellIdentifier"
        static let RANKING: String = "rankingCellIdentifier"
        static let CLASS_PLAYER: String = "classPlayerCellIdentifier"
        static let CLASS_USER_SELECTION: String = "userSelectionCellIdentifier"
        static let CLASS_COURSE_SELECTION: String = "courseSelectionCellIdentifier"
        static let CLUE_TYPE_SELECTION: String = "clueTypeSelectionCellIdentifier"
        static let GAME_CLUE: String = "gameClueCellIdentifier"
        static let CLUE_CREATION_MULTIPLE_CHOICE: String = "clueCreationMultipleChoiceCellIdentifier"
        static let GAME_TREASURE_SELECTION: String = "treasureSelectionCellIdentifier"
        static let GAME_CLUE_SELECTION: String = "clueSelectionCellIdentifier"
        static let GAME_CLASS_SELECTION: String = "classSelectionCellIdentifier"
        static let GAME_CLUE_CHOICE: String = "gameClueChoiceCellIdentifier"
    }
    
    struct image {
        static let GAV_USERS: UIImage = UIImage(named: "imgGAVUsers")!
        static let GAV_ADD_USER: UIImage = UIImage(named: "imgGAVAddUser")!
        static let GAV_COURSE: UIImage = UIImage(named: "imgGAVCourse")!
        static let GAV_COURSES: UIImage = UIImage(named: "imgGAVCourses")!
        static let GAV_ADD_COURSE: UIImage = UIImage(named: "imgGAVAddCourse")!
        static let GAV_CLASS: UIImage = UIImage(named: "imgGAVClass")!
        static let GAV_CLASSES: UIImage = UIImage(named: "imgGAVClasses")!
        static let GAV_ADD_CLASS: UIImage = UIImage(named: "imgGAVAddClass")!
        static let GAV_APPROVE: UIImage = UIImage(named: "imgGAVApprove")!
        static let GCV_CLUE: UIImage = UIImage(named: "imgGCVClue")!
        static let GCV_CLUES: UIImage = UIImage(named: "imgGCVClues")!
        static let GCV_ADD_CLUE: UIImage = UIImage(named: "imgGCVAddClue")!
        static let GCV_CLUE_TYPE_ID: UIImage = UIImage(named: "imgGCVClueTypeIdentification")!
        static let GCV_CLUE_TYPE_TF: UIImage = UIImage(named: "imgGCVClueTypeTrueOrFalse")!
        static let GCV_CLUE_TYPE_MC: UIImage = UIImage(named: "imgGCVClueTypeMultipleChoice")!
        static let GCV_CLUE_TYPE_ID_BIG: UIImage = UIImage(named: "imgGCVClueTypeIdentificationBig")!
        static let GCV_CLUE_TYPE_TF_BIG: UIImage = UIImage(named: "imgGCVClueTypeTrueOrFalseBig")!
        static let GCV_CLUE_TYPE_MC_BIG: UIImage = UIImage(named: "imgGCVClueTypeMultipleChoiceBig")!
        static let GCV_ADD_TREASURE: UIImage = UIImage(named: "imgGCVAddTreasure")!
        static let GCV_UNKNOWN_TREASURE: UIImage = UIImage(named: "imgGCVUnknownTreasure")!
        static let GCV_GAME: UIImage = UIImage(named: "imgGCVGame")!
        static let GCV_ADD_GAME: UIImage = UIImage(named: "imgGCVAddGame")!
        static let GCV_GAME_LOCKED: UIImage = UIImage(named: "imgGCVGameLocked")!
        static let GCV_GAME_UNLOCKED: UIImage = UIImage(named: "imgGCVGameUnlocked")!
        static let GCV_GAME_DEPLOY: UIImage = UIImage(named: "imgGCVGameDeploy")!
        static let GCV_GAME_VIEW_RESULTS: UIImage = UIImage(named: "imgGCVGameViewResults")!
        static let GPV_SIDEKICK_A: UIImage = UIImage(named: "imgGPVSidekickA")!
        static let GPV_SIDEKICK_B: UIImage = UIImage(named: "imgGPVSidekickB")!
        static let GPV_NAV_TREASURE: UIImage = UIImage(named: "imgGPVNavTreasure")!
        static let GPV_NAV_SIDEKICK: UIImage = UIImage(named: "imgGPVNavSidekick")!
        static let GPV_NAV_RANKING: UIImage = UIImage(named: "imgGPVNavRanking")!
        static let GPV_CLASS: UIImage = UIImage(named: "imgGPVClass")!
        static let GPV_TREASURE: UIImage = UIImage(named: "imgGPVTreasure")!
        static let GEN_PROGRESS: UIImage = UIImage(named: "imgGENProgress")!
        static let GEN_SEARCH: UIImage = UIImage(named: "imgGENSearch")!
        static let GEN_SORT: UIImage = UIImage(named: "imgGENSort")!
        static let GEN_UPDATE_WHITE: UIImage = UIImage(named: "imgGENUpdateWhite")!
        static let GEN_UPDATE_MAROON: UIImage = UIImage(named: "imgGENUpdateMaroon")!
        static let GEN_DELETE: UIImage = UIImage(named: "imgGENDelete")!
        static let GEN_ABOUT: UIImage = UIImage(named: "imgGENAbout")!
        static let GEN_CHEVRON: UIImage = UIImage(named: "imgGENChevron")!
        static let GEN_CHEVRON_NEXT: UIImage = UIImage(named: "imgGENChevronNext")!
        static let GEN_LOGOUT: UIImage = UIImage(named: "imgGENLogOut")!
        static let GEN_USER_INFO: UIImage = UIImage(named: "imgGENUserInfo")!
        static let GEN_GOODBYE: UIImage = UIImage(named: "imgGENGoodbye")!
        static let GEN_SAVE: UIImage = UIImage(named: "imgGENSave")!
        static let GEN_UNKNOWN_USER: UIImage = UIImage(named: "imgGENUnknownUser")!
        static let GEN_CLOSE: UIImage = UIImage(named: "imgGENClose")!
        static let GEN_SHOW_PASSWORD: UIImage = UIImage(named: "imgGENShowPassword")!
        static let GEN_HIDE_PASSWORD: UIImage = UIImage(named: "imgGENHidePassword")!
        static let GEN_ADMINISTRATOR: UIImage = UIImage(named: "imgGENAdministrator")!
        static let GEN_CREATOR: UIImage = UIImage(named: "imgGENCreator")!
        static let GEN_PLAYER: UIImage = UIImage(named: "imgGENPlayer")!
        static let GEN_RB_SELECTED: UIImage = UIImage(named: "imgGENRadioButtonSelected")!
        static let GEN_RB_UNSELECTED: UIImage = UIImage(named: "imgGENRadioButtonUnselected")!
        static let GEN_CB_SELECTED: UIImage = UIImage(named: "imgGENCheckBoxSelected")!
        static let GEN_CB_UNSELECTED: UIImage = UIImage(named: "imgGENCheckBoxUnselected")!
    }
    
    struct color {
        static let GAV_NAV_DASHBOARD: UIColor = UIColor(hex: "1D65A6")
        static let GAV_NAV_USR_MOD: UIColor = UIColor(hex: "72A2C0")
        static let GAV_NAV_CRS_MOD: UIColor = UIColor(hex: "00743F")
        static let GAV_NAV_CLA_MOD: UIColor = UIColor(hex: "F2A104")
        static let GCV_NAV_DASHBOARD: UIColor = UIColor(hex: "1D65A6")
        static let GCV_NAV_CLU_MOD: UIColor = UIColor(hex: "72A2C0")
        static let GCV_NAV_TRE_MOD: UIColor = UIColor(hex: "00743F")
        static let GCV_NAV_GAM_MOD: UIColor = UIColor(hex: "F2A104")
        static let GPV_NAV_DASHBOARD: UIColor = UIColor(hex: "0458AB")
        static let GEN_CREATE_ACTION: UIColor = UIColor(hex: "1D65A6")//UIColor(hex: "008744")
        static let GEN_UPDATE_ACTION: UIColor = UIColor(hex: "1D65A6")//UIColor(hex: "dc6900")
    }

    struct timeFormat {
        static let SERVER: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        static let CLIENT_DEFAULT: String = "yyyy-MM-dd HH:mm:ss +zzzz"
        static let CLIENT: String = "dd-MM-yyyy hh:mm:ss a"
        static let CLIENT_LONG_DATE_ONLY: String = "dd MMMM yyyy"
        static let CLIENT_LONG_DATE_TIME: String = "dd MMMM yyyy, hh:mm a"
        static let CLIENT_LONG_NON_MILITARY_TIME_ONLY: String = "hh:mm:ss a"
    }
    
    struct message {
        static let DEFAULT_ERROR: String = "Sorry, but there was an error processing your request. Please try again later."
    }
    
    struct apiKey {
        static let GOOGLE: String = "AIzaSyAnygAK6Bs167oTCXiaVBklfgVvwp71j6g"
    }
    
    struct directoryName {
        static let TREASURES: String = "Treasures"
    }
    
    struct clueType {
        static let ID: Int64 = 1
        static let MC: Int64 = 2
        static let TF: Int64 = 3
    }
    
    struct sidekick {
        static let A: Int64 = 0
        static let B: Int64 = 1
        static let SKILL_A_DIVISOR: Float = 600.0
        static let SKILL_B_DIVISOR: Float = 1000.0
        static let SKILL_C_DIVISOR: Float = 1400.0
        static let SKILL_D_DIVISOR: Float = 2000.0
        static let SKILL_E_DIVISOR: Float = 3000.0
    }
    
    struct gamePlay {
        static let ALTITUDE: Double = 3.0
        static let RADIUS: Double = 30.0
    }
}
