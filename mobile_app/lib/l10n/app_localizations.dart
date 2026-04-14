import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'OrderzHouse'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageSubtitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get notificationsSubtitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @noNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see notifications here when you receive them.'**
  String get noNotificationsMessage;

  /// No description provided for @projectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Project not found'**
  String get projectNotFound;

  /// No description provided for @projectNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This project may have been deleted or you don\'t have access to it.'**
  String get projectNotFoundMessage;

  /// No description provided for @backToNotifications.
  ///
  /// In en, this message translates to:
  /// **'Back to Notifications'**
  String get backToNotifications;

  /// No description provided for @loadingProject.
  ///
  /// In en, this message translates to:
  /// **'Loading project...'**
  String get loadingProject;

  /// No description provided for @thisNotificationHasNoLink.
  ///
  /// In en, this message translates to:
  /// **'This notification has no link'**
  String get thisNotificationHasNoLink;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage security settings'**
  String get securitySubtitle;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @twoFactorAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security'**
  String get twoFactorAuthSubtitle;

  /// No description provided for @enableTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Enable Two-Factor Authentication'**
  String get enableTwoFactor;

  /// No description provided for @disableTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Disable Two-Factor Authentication'**
  String get disableTwoFactor;

  /// No description provided for @securityCenter.
  ///
  /// In en, this message translates to:
  /// **'Security Center'**
  String get securityCenter;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get changePasswordSubtitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect current password'**
  String get incorrectPassword;

  /// No description provided for @myContent.
  ///
  /// In en, this message translates to:
  /// **'My Content'**
  String get myContent;

  /// No description provided for @myContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your uploaded content'**
  String get myContentSubtitle;

  /// No description provided for @uploadedFiles.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Files'**
  String get uploadedFiles;

  /// No description provided for @noUploadedFiles.
  ///
  /// In en, this message translates to:
  /// **'No uploaded files'**
  String get noUploadedFiles;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help and contact us'**
  String get supportSubtitle;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @yourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Message'**
  String get yourMessage;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully'**
  String get messageSent;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccountWarning;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get confirmDeleteAccount;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeleted;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDeleteToConfirm;

  /// No description provided for @deleteAccountInputHint.
  ///
  /// In en, this message translates to:
  /// **'Tap here and type DELETE (English, all caps)'**
  String get deleteAccountInputHint;

  /// No description provided for @deleteAccountMismatchHint.
  ///
  /// In en, this message translates to:
  /// **'The button stays off until this field is exactly the English word DELETE (no extra letters or spaces).'**
  String get deleteAccountMismatchHint;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @addSkill.
  ///
  /// In en, this message translates to:
  /// **'Add Skill'**
  String get addSkill;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolio;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMessage;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @myProjects.
  ///
  /// In en, this message translates to:
  /// **'My Projects'**
  String get myProjects;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @adminMobileHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin account'**
  String get adminMobileHomeTitle;

  /// No description provided for @adminMobileHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Browse the marketplace, payments, and profile below. For the same admin tools as the website (plans, users, approvals, analytics, …), open a shortcut — it opens inside the app.'**
  String get adminMobileHomeBody;

  /// No description provided for @adminFullDashboardCaption.
  ///
  /// In en, this message translates to:
  /// **'Below is the same admin website as on desktop—sign in here if needed. Use the menu button to jump to a section or reload.'**
  String get adminFullDashboardCaption;

  /// No description provided for @adminWebJumpToSection.
  ///
  /// In en, this message translates to:
  /// **'Jump to section'**
  String get adminWebJumpToSection;

  /// No description provided for @adminWebReloadPage.
  ///
  /// In en, this message translates to:
  /// **'Reload page'**
  String get adminWebReloadPage;

  /// No description provided for @adminWebDashboardSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin dashboard'**
  String get adminWebDashboardSectionTitle;

  /// No description provided for @adminWebDashboardSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Runs here in the app (same website as desktop). Sign in with your admin account when the login screen appears.'**
  String get adminWebDashboardSectionHint;

  /// No description provided for @adminWebLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get adminWebLaunchFailed;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @phoneNumberWhyWeCollectHint.
  ///
  /// In en, this message translates to:
  /// **'Administrators may use this number to contact you about your account when needed—for example if a serious issue is reported—or to thank you and offer support. Full details are in the Privacy Policy.'**
  String get phoneNumberWhyWeCollectHint;

  /// No description provided for @blockedPeople.
  ///
  /// In en, this message translates to:
  /// **'Blocked people'**
  String get blockedPeople;

  /// No description provided for @blockedPeopleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage users you blocked from project chat'**
  String get blockedPeopleSubtitle;

  /// No description provided for @blockedPeopleFooter.
  ///
  /// In en, this message translates to:
  /// **'Blocking is saved on your account and applies in project chat everywhere you use the app. For serious abuse, also submit a report so our team can review.'**
  String get blockedPeopleFooter;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockUser;

  /// No description provided for @unblockUserConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock this user?'**
  String get unblockUserConfirmTitle;

  /// No description provided for @unblockUserConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will see their messages in project chat again on this device.'**
  String get unblockUserConfirmBody;

  /// No description provided for @reportMessage.
  ///
  /// In en, this message translates to:
  /// **'Report message'**
  String get reportMessage;

  /// No description provided for @reportMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Report to support'**
  String get reportMessageTitle;

  /// No description provided for @reportMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: describe what is wrong (helps us review faster).'**
  String get reportMessageHint;

  /// No description provided for @reportMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Report opened in your mail app'**
  String get reportMessageSent;

  /// No description provided for @reportSubmittedToTeam.
  ///
  /// In en, this message translates to:
  /// **'Thanks — your report was sent to our team for review.'**
  String get reportSubmittedToTeam;

  /// No description provided for @blockSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not block this user. Check your connection and try again.'**
  String get blockSubmitFailed;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @blockUserConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get blockUserConfirmTitle;

  /// No description provided for @blockUserConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will no longer see their messages in this project’s chat on any device while they are blocked. You can unblock them anytime in Settings under Blocked people.'**
  String get blockUserConfirmBody;

  /// No description provided for @userBlockedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get userBlockedSnackbar;

  /// No description provided for @userUnblockedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'User unblocked'**
  String get userUnblockedSnackbar;

  /// No description provided for @projectDetailsTooltipMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages — chat with the other party'**
  String get projectDetailsTooltipMessages;

  /// No description provided for @projectDetailsTooltipChangeRequests.
  ///
  /// In en, this message translates to:
  /// **'Change requests — scope / revision requests'**
  String get projectDetailsTooltipChangeRequests;

  /// No description provided for @projectChatHowToHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: press and hold someone else\'s message, then choose Report or Block. To unblock: Settings → Blocked people. Tap (i) for rules and support.'**
  String get projectChatHowToHint;

  /// No description provided for @projectChatSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety in chat'**
  String get projectChatSafetyTitle;

  /// No description provided for @projectChatSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Harassment, spam, and illegal content are not allowed. Long-press someone else\'s message to report it or block the user. See Terms (Acceptable Use) for full rules.'**
  String get projectChatSafetyBody;

  /// No description provided for @projectChatOpenTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & acceptable use'**
  String get projectChatOpenTerms;

  /// No description provided for @projectChatOpenSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get projectChatOpenSupport;

  /// No description provided for @projectChatBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show here'**
  String get projectChatBlockedTitle;

  /// No description provided for @projectChatHiddenByBlocks.
  ///
  /// In en, this message translates to:
  /// **'Messages from blocked users are hidden. Unblock in Settings if needed.'**
  String get projectChatHiddenByBlocks;

  /// No description provided for @projectChatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get projectChatEmptyTitle;

  /// No description provided for @projectChatEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No messages have been sent for this project.'**
  String get projectChatEmptyMessage;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @expandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get expandAll;

  /// No description provided for @collapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get collapseAll;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @policySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter sections…'**
  String get policySearchHint;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get learnMore;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @supportEmailDraftCopied.
  ///
  /// In en, this message translates to:
  /// **'Could not open an email app. Your message was copied — paste it into Mail or another email app and send to info@battechno.com.'**
  String get supportEmailDraftCopied;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get sessionExpired;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get createProject;

  /// No description provided for @postProject.
  ///
  /// In en, this message translates to:
  /// **'Post a Project'**
  String get postProject;

  /// No description provided for @browseProjects.
  ///
  /// In en, this message translates to:
  /// **'Browse Projects'**
  String get browseProjects;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetails;

  /// No description provided for @projectTitle.
  ///
  /// In en, this message translates to:
  /// **'Project Title'**
  String get projectTitle;

  /// No description provided for @projectDescription.
  ///
  /// In en, this message translates to:
  /// **'Project Description'**
  String get projectDescription;

  /// No description provided for @projectBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get projectBudget;

  /// No description provided for @projectDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get projectDeadline;

  /// No description provided for @projectCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get projectCategory;

  /// No description provided for @projectStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get projectStatus;

  /// No description provided for @projectType.
  ///
  /// In en, this message translates to:
  /// **'Project Type'**
  String get projectType;

  /// No description provided for @fixedPrice.
  ///
  /// In en, this message translates to:
  /// **'Fixed Price'**
  String get fixedPrice;

  /// No description provided for @hourlyRate_.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate_;

  /// No description provided for @estimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated Duration'**
  String get estimatedDuration;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @deliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery Date'**
  String get deliveryDate;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get addAttachment;

  /// No description provided for @requirements.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get requirements;

  /// No description provided for @milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestones;

  /// No description provided for @addMilestone.
  ///
  /// In en, this message translates to:
  /// **'Add Milestone'**
  String get addMilestone;

  /// No description provided for @projectCreated.
  ///
  /// In en, this message translates to:
  /// **'Project created successfully'**
  String get projectCreated;

  /// No description provided for @projectUpdated.
  ///
  /// In en, this message translates to:
  /// **'Project updated successfully'**
  String get projectUpdated;

  /// No description provided for @projectDeleted.
  ///
  /// In en, this message translates to:
  /// **'Project deleted successfully'**
  String get projectDeleted;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjects;

  /// No description provided for @noProjectsMessage.
  ///
  /// In en, this message translates to:
  /// **'Your projects will appear here'**
  String get noProjectsMessage;

  /// No description provided for @applicants.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get applicants;

  /// No description provided for @applications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applications;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// No description provided for @applied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get applied;

  /// No description provided for @applicationSent.
  ///
  /// In en, this message translates to:
  /// **'Application sent successfully'**
  String get applicationSent;

  /// No description provided for @applicationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Application accepted'**
  String get applicationAccepted;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application rejected'**
  String get applicationRejected;

  /// No description provided for @noApplicants.
  ///
  /// In en, this message translates to:
  /// **'No applicants yet'**
  String get noApplicants;

  /// No description provided for @viewApplicants.
  ///
  /// In en, this message translates to:
  /// **'View Applicants'**
  String get viewApplicants;

  /// No description provided for @acceptApplication.
  ///
  /// In en, this message translates to:
  /// **'Accept Application'**
  String get acceptApplication;

  /// No description provided for @rejectApplication.
  ///
  /// In en, this message translates to:
  /// **'Reject Application'**
  String get rejectApplication;

  /// No description provided for @coverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover Letter'**
  String get coverLetter;

  /// No description provided for @proposedBudget.
  ///
  /// In en, this message translates to:
  /// **'Proposed Budget'**
  String get proposedBudget;

  /// No description provided for @proposedDuration.
  ///
  /// In en, this message translates to:
  /// **'Proposed Duration'**
  String get proposedDuration;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @offer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get offer;

  /// No description provided for @makeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make an Offer'**
  String get makeOffer;

  /// No description provided for @submitOffer.
  ///
  /// In en, this message translates to:
  /// **'Submit Offer'**
  String get submitOffer;

  /// No description provided for @offerAmount.
  ///
  /// In en, this message translates to:
  /// **'Offer Amount'**
  String get offerAmount;

  /// No description provided for @offerMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get offerMessage;

  /// No description provided for @offerSent.
  ///
  /// In en, this message translates to:
  /// **'Offer sent successfully'**
  String get offerSent;

  /// No description provided for @offerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted'**
  String get offerAccepted;

  /// No description provided for @offerRejected.
  ///
  /// In en, this message translates to:
  /// **'Offer rejected'**
  String get offerRejected;

  /// No description provided for @noOffers.
  ///
  /// In en, this message translates to:
  /// **'No offers yet'**
  String get noOffers;

  /// No description provided for @viewOffers.
  ///
  /// In en, this message translates to:
  /// **'View Offers'**
  String get viewOffers;

  /// No description provided for @acceptOffer.
  ///
  /// In en, this message translates to:
  /// **'Accept Offer'**
  String get acceptOffer;

  /// No description provided for @rejectOffer.
  ///
  /// In en, this message translates to:
  /// **'Reject Offer'**
  String get rejectOffer;

  /// No description provided for @counterOffer.
  ///
  /// In en, this message translates to:
  /// **'Counter Offer'**
  String get counterOffer;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @submitDelivery.
  ///
  /// In en, this message translates to:
  /// **'Submit Delivery'**
  String get submitDelivery;

  /// No description provided for @deliverySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Delivery submitted successfully'**
  String get deliverySubmitted;

  /// No description provided for @deliveryApproved.
  ///
  /// In en, this message translates to:
  /// **'Delivery approved'**
  String get deliveryApproved;

  /// No description provided for @deliveryRejected.
  ///
  /// In en, this message translates to:
  /// **'Delivery rejected'**
  String get deliveryRejected;

  /// No description provided for @noDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No deliveries yet'**
  String get noDeliveries;

  /// No description provided for @viewDeliveries.
  ///
  /// In en, this message translates to:
  /// **'View Deliveries'**
  String get viewDeliveries;

  /// No description provided for @deliveryFiles.
  ///
  /// In en, this message translates to:
  /// **'Delivery Files'**
  String get deliveryFiles;

  /// No description provided for @deliveryNote.
  ///
  /// In en, this message translates to:
  /// **'Delivery Note'**
  String get deliveryNote;

  /// No description provided for @latestDelivery.
  ///
  /// In en, this message translates to:
  /// **'Latest Delivery'**
  String get latestDelivery;

  /// No description provided for @deliveryHistory.
  ///
  /// In en, this message translates to:
  /// **'Delivery History'**
  String get deliveryHistory;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get uploadFile;

  /// No description provided for @downloadFile.
  ///
  /// In en, this message translates to:
  /// **'Download File'**
  String get downloadFile;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @fileUploaded.
  ///
  /// In en, this message translates to:
  /// **'File uploaded successfully'**
  String get fileUploaded;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved to {path}'**
  String fileSaved(Object path);

  /// No description provided for @noFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get noFiles;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @selectFiles.
  ///
  /// In en, this message translates to:
  /// **'Select Files'**
  String get selectFiles;

  /// No description provided for @maxFileSize.
  ///
  /// In en, this message translates to:
  /// **'Max file size: {size}MB'**
  String maxFileSize(Object size);

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @requestChanges.
  ///
  /// In en, this message translates to:
  /// **'Request Changes'**
  String get requestChanges;

  /// No description provided for @changesRequested.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get changesRequested;

  /// No description provided for @revisionRequested.
  ///
  /// In en, this message translates to:
  /// **'Revision requested'**
  String get revisionRequested;

  /// No description provided for @enterChangeRequest.
  ///
  /// In en, this message translates to:
  /// **'Enter your change request'**
  String get enterChangeRequest;

  /// No description provided for @changeRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Change request sent'**
  String get changeRequestSent;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @receiveProject.
  ///
  /// In en, this message translates to:
  /// **'Receive Project'**
  String get receiveProject;

  /// No description provided for @reviewDelivery.
  ///
  /// In en, this message translates to:
  /// **'Review Delivery'**
  String get reviewDelivery;

  /// No description provided for @approveDelivery.
  ///
  /// In en, this message translates to:
  /// **'Approve Delivery'**
  String get approveDelivery;

  /// No description provided for @projectApproved.
  ///
  /// In en, this message translates to:
  /// **'Project approved and marked as completed'**
  String get projectApproved;

  /// No description provided for @projectCompleted.
  ///
  /// In en, this message translates to:
  /// **'Project completed'**
  String get projectCompleted;

  /// No description provided for @yourWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Your Workspace'**
  String get yourWorkspace;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get actionRequired;

  /// No description provided for @noActionsRequired.
  ///
  /// In en, this message translates to:
  /// **'No actions required'**
  String get noActionsRequired;

  /// No description provided for @noActiveProjects.
  ///
  /// In en, this message translates to:
  /// **'No active projects'**
  String get noActiveProjects;

  /// No description provided for @getInspired.
  ///
  /// In en, this message translates to:
  /// **'Get Inspired'**
  String get getInspired;

  /// No description provided for @recommendedProjects.
  ///
  /// In en, this message translates to:
  /// **'Recommended Projects'**
  String get recommendedProjects;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloUser(Object name);

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email'**
  String get resetLinkSent;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get enterVerificationCode;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to {destination}'**
  String otpSentTo(Object destination);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(Object seconds);

  /// No description provided for @codeExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired'**
  String get codeExpired;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @verificationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Verification successful'**
  String get verificationSuccessful;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the'**
  String get iAgreeToThe;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @acceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Accept Terms'**
  String get acceptTerms;

  /// No description provided for @pleaseAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions'**
  String get pleaseAcceptTerms;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @freelancer.
  ///
  /// In en, this message translates to:
  /// **'Freelancer'**
  String get freelancer;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get selectRole;

  /// No description provided for @asClient.
  ///
  /// In en, this message translates to:
  /// **'As a Client'**
  String get asClient;

  /// No description provided for @asFreelancer.
  ///
  /// In en, this message translates to:
  /// **'As a Freelancer'**
  String get asFreelancer;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @yourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your Balance'**
  String get yourBalance;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @availableToWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Available to withdraw'**
  String get availableToWithdraw;

  /// No description provided for @pendingBalance.
  ///
  /// In en, this message translates to:
  /// **'Pending Balance'**
  String get pendingBalance;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @viewEarnings.
  ///
  /// In en, this message translates to:
  /// **'View Earnings'**
  String get viewEarnings;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @withdrawFunds.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Funds'**
  String get withdrawFunds;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @addFunds.
  ///
  /// In en, this message translates to:
  /// **'Add Funds'**
  String get addFunds;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @manageProjects.
  ///
  /// In en, this message translates to:
  /// **'Manage your projects'**
  String get manageProjects;

  /// No description provided for @viewProjects.
  ///
  /// In en, this message translates to:
  /// **'View Projects'**
  String get viewProjects;

  /// No description provided for @projectsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Projects'**
  String projectsCount(Object count);

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn'**
  String get referAndEarn;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends and earn rewards'**
  String get inviteFriends;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referralCode;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get yourReferralCode;

  /// No description provided for @shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share Invite'**
  String get shareInvite;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @invited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get invited;

  /// No description provided for @successful.
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get successful;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @referralBannerText.
  ///
  /// In en, this message translates to:
  /// **'Invite a friend and earn 5% of the registration fee when they sign up.'**
  String get referralBannerText;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied'**
  String get codeCopied;

  /// No description provided for @shareMessage.
  ///
  /// In en, this message translates to:
  /// **'Join me on OrderzHouse! Use my referral code: {code} when you sign up.'**
  String shareMessage(Object code);

  /// No description provided for @helpFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpFaq;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @howCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get howCanWeHelp;

  /// No description provided for @searchHelp.
  ///
  /// In en, this message translates to:
  /// **'Search for help'**
  String get searchHelp;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get viewPlans;

  /// No description provided for @wantMoreFeatures.
  ///
  /// In en, this message translates to:
  /// **'Want to access more features?'**
  String get wantMoreFeatures;

  /// No description provided for @upgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlan;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get freePlan;

  /// No description provided for @premiumPlan.
  ///
  /// In en, this message translates to:
  /// **'Premium Plan'**
  String get premiumPlan;

  /// No description provided for @proPlan.
  ///
  /// In en, this message translates to:
  /// **'Pro Plan'**
  String get proPlan;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @managePlan.
  ///
  /// In en, this message translates to:
  /// **'Manage Plan'**
  String get managePlan;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get cancelSubscription;

  /// No description provided for @renewSubscription.
  ///
  /// In en, this message translates to:
  /// **'Renew Subscription'**
  String get renewSubscription;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @failedToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoadData;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @searchFreelancers.
  ///
  /// In en, this message translates to:
  /// **'Search freelancers, categories'**
  String get searchFreelancers;

  /// No description provided for @searchProjects.
  ///
  /// In en, this message translates to:
  /// **'Search projects, categories'**
  String get searchProjects;

  /// No description provided for @savedProjects.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedProjects;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get searchCategories;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @minBudget.
  ///
  /// In en, this message translates to:
  /// **'Min Budget'**
  String get minBudget;

  /// No description provided for @maxBudget.
  ///
  /// In en, this message translates to:
  /// **'Max Budget'**
  String get maxBudget;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service Fee'**
  String get serviceFee;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @ratings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get ratings;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @noReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviews;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get averageRating;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get categoryRequired;

  /// No description provided for @budgetRequired.
  ///
  /// In en, this message translates to:
  /// **'Budget is required'**
  String get budgetRequired;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get invalidAmount;

  /// No description provided for @minLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum {count} characters required'**
  String minLength(Object count);

  /// No description provided for @maxLength.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} characters allowed'**
  String maxLength(Object count);

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @attention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get attention;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String lastSeen(Object time);

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(Object current, Object total);

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfo;

  /// No description provided for @projectDetails_.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetails_;

  /// No description provided for @budgetAndTimeline.
  ///
  /// In en, this message translates to:
  /// **'Budget & Timeline'**
  String get budgetAndTimeline;

  /// No description provided for @reviewAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get reviewAndSubmit;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional Details'**
  String get additionalDetails;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter title'**
  String get enterTitle;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @describeYourProject.
  ///
  /// In en, this message translates to:
  /// **'Describe your project'**
  String get describeYourProject;

  /// No description provided for @whatAreYouLookingFor.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get whatAreYouLookingFor;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @pickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get pickTime;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @messagesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Messages screen coming soon'**
  String get messagesComingSoon;

  /// No description provided for @tasksComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Tasks screen coming soon'**
  String get tasksComingSoon;

  /// No description provided for @appointmentsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Appointments screen coming soon'**
  String get appointmentsComingSoon;

  /// No description provided for @couldntOpenNotification.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this notification. Missing {data} data.'**
  String couldntOpenNotification(Object data);

  /// No description provided for @healthCheck.
  ///
  /// In en, this message translates to:
  /// **'Health Check'**
  String get healthCheck;

  /// No description provided for @serverStatus.
  ///
  /// In en, this message translates to:
  /// **'Server Status'**
  String get serverStatus;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get choosePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @talent.
  ///
  /// In en, this message translates to:
  /// **'Talent'**
  String get talent;

  /// No description provided for @talents.
  ///
  /// In en, this message translates to:
  /// **'Talents'**
  String get talents;

  /// No description provided for @viewTalent.
  ///
  /// In en, this message translates to:
  /// **'View Talent'**
  String get viewTalent;

  /// No description provided for @hireTalent.
  ///
  /// In en, this message translates to:
  /// **'Hire Talent'**
  String get hireTalent;

  /// No description provided for @topTalents.
  ///
  /// In en, this message translates to:
  /// **'Top Talents'**
  String get topTalents;

  /// No description provided for @onboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboarding;

  /// No description provided for @welcomeToApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to OrderzHouse'**
  String get welcomeToApp;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Find the best freelancers'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Connect with skilled professionals for your projects'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Post your projects'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Create projects and receive offers from freelancers'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Secure payments'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Safe and secure payment processing'**
  String get onboardingDesc3;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get splashLoading;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @enableNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified about project updates and messages'**
  String get enableNotificationsDesc;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportBug;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @featureNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This feature is not available yet'**
  String get featureNotAvailable;

  /// No description provided for @stayTuned.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned for updates'**
  String get stayTuned;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelp;

  /// No description provided for @weWillReplyByEmail.
  ///
  /// In en, this message translates to:
  /// **'Send us a message and we\'ll reply by email.'**
  String get weWillReplyByEmail;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @describeYourIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue or question...'**
  String get describeYourIssue;

  /// No description provided for @messageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get messageRequired;

  /// No description provided for @messageTooShort.
  ///
  /// In en, this message translates to:
  /// **'Message must be at least 10 characters'**
  String get messageTooShort;

  /// No description provided for @messageSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Message sent! We\'ll reply by email.'**
  String get messageSentSuccess;

  /// No description provided for @errorSendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Error sending message'**
  String get errorSendingMessage;

  /// No description provided for @couldNotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open email client'**
  String get couldNotOpenEmail;

  /// No description provided for @emailCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Email copied to clipboard'**
  String get emailCopiedToClipboard;

  /// No description provided for @subjectAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get subjectAccount;

  /// No description provided for @subjectPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get subjectPayments;

  /// No description provided for @subjectProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get subjectProjects;

  /// No description provided for @subjectBug.
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get subjectBug;

  /// No description provided for @subjectOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get subjectOther;

  /// No description provided for @deleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete your account'**
  String get deleteYourAccount;

  /// No description provided for @deleteDataWarningFull.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all your data (projects, posts, payments history, etc.). This action can\'t be undone.'**
  String get deleteDataWarningFull;

  /// No description provided for @whatWillBeDeleted.
  ///
  /// In en, this message translates to:
  /// **'What will be deleted'**
  String get whatWillBeDeleted;

  /// No description provided for @accountProfile.
  ///
  /// In en, this message translates to:
  /// **'Account profile'**
  String get accountProfile;

  /// No description provided for @postsProjectsContent.
  ///
  /// In en, this message translates to:
  /// **'Posts/projects/content'**
  String get postsProjectsContent;

  /// No description provided for @paymentHistoryItem.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistoryItem;

  /// No description provided for @referralsRewards.
  ///
  /// In en, this message translates to:
  /// **'Referrals & rewards'**
  String get referralsRewards;

  /// No description provided for @confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @cannotBeUndoneWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Your account and all associated data will be permanently deleted.'**
  String get cannotBeUndoneWarning;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @yourAccountProtected.
  ///
  /// In en, this message translates to:
  /// **'Your account is protected with two-factor authentication. You\'ll receive a verification code via email when signing in.'**
  String get yourAccountProtected;

  /// No description provided for @add2FADescription.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security to your account. Enable 2FA to receive verification codes via email when signing in.'**
  String get add2FADescription;

  /// No description provided for @manage2FA.
  ///
  /// In en, this message translates to:
  /// **'Manage 2FA'**
  String get manage2FA;

  /// No description provided for @enable2FA.
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA'**
  String get enable2FA;

  /// No description provided for @enable2FATitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Two-Factor Authentication'**
  String get enable2FATitle;

  /// No description provided for @enable2FADescription.
  ///
  /// In en, this message translates to:
  /// **'Two-factor authentication adds an extra layer of security to your account. You\'ll receive a code via email to verify your identity when signing in.'**
  String get enable2FADescription;

  /// No description provided for @disable2FATitle.
  ///
  /// In en, this message translates to:
  /// **'Disable Two-Factor Authentication?'**
  String get disable2FATitle;

  /// No description provided for @disable2FADescription.
  ///
  /// In en, this message translates to:
  /// **'This will make your account less secure. Are you sure you want to disable 2FA?'**
  String get disable2FADescription;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @changePasswordFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Change password feature coming soon'**
  String get changePasswordFeatureComingSoon;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get newPasswordRequired;

  /// No description provided for @newPasswordMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current password'**
  String get newPasswordMustBeDifferent;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @pleaseFillAllFieldsCorrectly.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields correctly'**
  String get pleaseFillAllFieldsCorrectly;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// No description provided for @unsavedChangesWarning.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to go back?'**
  String get unsavedChangesWarning;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @receivePushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications on your device'**
  String get receivePushNotifications;

  /// No description provided for @projectUpdates.
  ///
  /// In en, this message translates to:
  /// **'Project Updates'**
  String get projectUpdates;

  /// No description provided for @projectUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications about your projects'**
  String get projectUpdatesSubtitle;

  /// No description provided for @messagesNotifications.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesNotifications;

  /// No description provided for @messagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct messages and conversations'**
  String get messagesSubtitle;

  /// No description provided for @paymentsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsNotifications;

  /// No description provided for @paymentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payment updates and transactions'**
  String get paymentsSubtitle;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @promotionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Special offers and announcements'**
  String get promotionsSubtitle;

  /// No description provided for @contentDeletedNotice.
  ///
  /// In en, this message translates to:
  /// **'Your uploaded content will be deleted when you delete your account.'**
  String get contentDeletedNotice;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @updatedToday.
  ///
  /// In en, this message translates to:
  /// **'Updated today'**
  String get updatedToday;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @noRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions'**
  String get noRecentTransactions;

  /// No description provided for @plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plans;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @hideReferEarn.
  ///
  /// In en, this message translates to:
  /// **'Hide Refer & Earn'**
  String get hideReferEarn;

  /// No description provided for @referralCodeNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Referral code not available'**
  String get referralCodeNotAvailable;

  /// No description provided for @addProject.
  ///
  /// In en, this message translates to:
  /// **'Add Project'**
  String get addProject;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get priceLowToHigh;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get priceHighToLow;

  /// No description provided for @yourAssignedProjectsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your assigned projects will appear here'**
  String get yourAssignedProjectsAppearHere;

  /// No description provided for @createFirstProject.
  ///
  /// In en, this message translates to:
  /// **'Create your first project to get started'**
  String get createFirstProject;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @noChangesToSave.
  ///
  /// In en, this message translates to:
  /// **'No changes to save'**
  String get noChangesToSave;

  /// No description provided for @authRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required. Please login.'**
  String get authRequired;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @phoneMustBe10Digits.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be exactly 10 digits'**
  String get phoneMustBe10Digits;

  /// No description provided for @projectTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Project Title *'**
  String get projectTitleLabel;

  /// No description provided for @projectTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter project title (10-100 characters)'**
  String get projectTitleHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your project (100-2000 characters)'**
  String get descriptionHint;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get categoryLabel;

  /// No description provided for @selectCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategoryHint;

  /// No description provided for @subSubCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Sub-Sub-Category *'**
  String get subSubCategoryLabel;

  /// No description provided for @selectSubSubCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select sub-sub-category'**
  String get selectSubSubCategoryHint;

  /// No description provided for @projectTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Project Type *'**
  String get projectTypeLabel;

  /// No description provided for @selectProjectTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select project type'**
  String get selectProjectTypeHint;

  /// No description provided for @projectTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed Price'**
  String get projectTypeFixed;

  /// No description provided for @projectTypeHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get projectTypeHourly;

  /// No description provided for @projectTypeBidding.
  ///
  /// In en, this message translates to:
  /// **'Bidding'**
  String get projectTypeBidding;

  /// No description provided for @budgetJodLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget (JOD) *'**
  String get budgetJodLabel;

  /// No description provided for @hourlyRateJodLabel.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate (JOD) *'**
  String get hourlyRateJodLabel;

  /// No description provided for @minBudgetJodLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Budget (JOD) *'**
  String get minBudgetJodLabel;

  /// No description provided for @maxBudgetJodLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Budget (JOD) *'**
  String get maxBudgetJodLabel;

  /// No description provided for @durationTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration Type *'**
  String get durationTypeLabel;

  /// No description provided for @selectDurationTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select duration type'**
  String get selectDurationTypeHint;

  /// No description provided for @durationTypeDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get durationTypeDays;

  /// No description provided for @durationTypeHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get durationTypeHours;

  /// No description provided for @durationDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (Days) *'**
  String get durationDaysLabel;

  /// No description provided for @durationHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (Hours) *'**
  String get durationHoursLabel;

  /// No description provided for @preferredSkillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Skills (comma-separated)'**
  String get preferredSkillsLabel;

  /// No description provided for @preferredSkillsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Flutter, Design, Marketing'**
  String get preferredSkillsHint;

  /// No description provided for @failedToLoadCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get failedToLoadCategories;

  /// No description provided for @projectCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Project Cover Image'**
  String get projectCoverImage;

  /// No description provided for @coverImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Add an optional cover image for your project. This will help attract freelancers.'**
  String get coverImageDescription;

  /// No description provided for @tapToAddCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to add cover image'**
  String get tapToAddCoverImage;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get failedToPickImage;

  /// No description provided for @projectFiles.
  ///
  /// In en, this message translates to:
  /// **'Project Files'**
  String get projectFiles;

  /// No description provided for @projectFilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Add optional files related to your project (max 5 files).'**
  String get projectFilesDescription;

  /// No description provided for @addFilesCount.
  ///
  /// In en, this message translates to:
  /// **'Add Files ({current}/{max})'**
  String addFilesCount(Object current, Object max);

  /// No description provided for @noFilesAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No files added yet'**
  String get noFilesAddedYet;

  /// No description provided for @maxFilesAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} files allowed. Please remove some files first.'**
  String maxFilesAllowed(Object count);

  /// No description provided for @failedToPickFiles.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick files'**
  String get failedToPickFiles;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get paymentSummary;

  /// No description provided for @paymentSummaryDescription.
  ///
  /// In en, this message translates to:
  /// **'Review your project details and proceed to payment.'**
  String get paymentSummaryDescription;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(Object count);

  /// No description provided for @hoursCount.
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String hoursCount(Object count);

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @stripePaymentInfo.
  ///
  /// In en, this message translates to:
  /// **'You will be redirected to Stripe to complete the payment securely.'**
  String get stripePaymentInfo;

  /// No description provided for @payWithStripe.
  ///
  /// In en, this message translates to:
  /// **'Pay with Stripe'**
  String get payWithStripe;

  /// No description provided for @titleIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleIsRequired;

  /// No description provided for @titleLengthError.
  ///
  /// In en, this message translates to:
  /// **'Title must be between 10 and 100 characters'**
  String get titleLengthError;

  /// No description provided for @descriptionIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionIsRequired;

  /// No description provided for @descriptionLengthError.
  ///
  /// In en, this message translates to:
  /// **'Description must be between 100 and 2000 characters'**
  String get descriptionLengthError;

  /// No description provided for @categoryIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get categoryIsRequired;

  /// No description provided for @subSubCategoryIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Sub-sub-category is required'**
  String get subSubCategoryIsRequired;

  /// No description provided for @projectTypeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Project type is required'**
  String get projectTypeIsRequired;

  /// No description provided for @budgetIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Budget is required and must be greater than 0'**
  String get budgetIsRequired;

  /// No description provided for @hourlyRateIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate is required and must be greater than 0'**
  String get hourlyRateIsRequired;

  /// No description provided for @minBudgetIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum budget is required and must be greater than 0'**
  String get minBudgetIsRequired;

  /// No description provided for @maxBudgetIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Maximum budget is required and must be greater than 0'**
  String get maxBudgetIsRequired;

  /// No description provided for @maxBudgetMustBeGreater.
  ///
  /// In en, this message translates to:
  /// **'Maximum budget must be greater than or equal to minimum budget'**
  String get maxBudgetMustBeGreater;

  /// No description provided for @durationTypeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Duration type is required'**
  String get durationTypeIsRequired;

  /// No description provided for @durationDaysIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Duration days is required and must be greater than 0'**
  String get durationDaysIsRequired;

  /// No description provided for @durationHoursIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Duration hours is required and must be greater than 0'**
  String get durationHoursIsRequired;

  /// No description provided for @maxFilesError.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 files allowed'**
  String get maxFilesError;

  /// No description provided for @projectCreatedButFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Project created but failed to upload files: {message}'**
  String projectCreatedButFilesFailed(Object message);

  /// No description provided for @couldNotLaunchCheckout.
  ///
  /// In en, this message translates to:
  /// **'Could not launch checkout URL'**
  String get couldNotLaunchCheckout;

  /// No description provided for @naNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get naNotAvailable;

  /// No description provided for @offerRejectedMsg.
  ///
  /// In en, this message translates to:
  /// **'Offer rejected'**
  String get offerRejectedMsg;

  /// No description provided for @offerAcceptedMsg.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted ✅'**
  String get offerAcceptedMsg;

  /// No description provided for @applicationRejectedMsg.
  ///
  /// In en, this message translates to:
  /// **'Application rejected'**
  String get applicationRejectedMsg;

  /// No description provided for @applicationAcceptedMsg.
  ///
  /// In en, this message translates to:
  /// **'Application accepted ✅'**
  String get applicationAcceptedMsg;

  /// No description provided for @failedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedWithError(Object error);

  /// No description provided for @projectApprovedMsg.
  ///
  /// In en, this message translates to:
  /// **'Project approved ✅'**
  String get projectApprovedMsg;

  /// No description provided for @failedToApprove.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve: {error}'**
  String failedToApprove(Object error);

  /// No description provided for @pleaseEnterMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get pleaseEnterMessage;

  /// No description provided for @changeRequestSentMsg.
  ///
  /// In en, this message translates to:
  /// **'Change request sent ✉️'**
  String get changeRequestSentMsg;

  /// No description provided for @failedToSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request: {error}'**
  String failedToSendRequest(Object error);

  /// No description provided for @enterFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your feedback or change requests...'**
  String get enterFeedbackHint;

  /// No description provided for @exploreTalents.
  ///
  /// In en, this message translates to:
  /// **'Explore Talents'**
  String get exploreTalents;

  /// No description provided for @noFreelancersFound.
  ///
  /// In en, this message translates to:
  /// **'No freelancers found'**
  String get noFreelancersFound;

  /// No description provided for @selectAtLeastOneFile.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one file'**
  String get selectAtLeastOneFile;

  /// No description provided for @failedToDeliver.
  ///
  /// In en, this message translates to:
  /// **'Failed to deliver: {error}'**
  String failedToDeliver(Object error);

  /// No description provided for @noDeliveriesToReview.
  ///
  /// In en, this message translates to:
  /// **'No deliveries to review yet'**
  String get noDeliveriesToReview;

  /// No description provided for @deliveryApprovedMsg.
  ///
  /// In en, this message translates to:
  /// **'Delivery approved!'**
  String get deliveryApprovedMsg;

  /// No description provided for @changesRequestedMsg.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get changesRequestedMsg;

  /// No description provided for @failedToSendOffer.
  ///
  /// In en, this message translates to:
  /// **'Failed to send offer: {error}'**
  String failedToSendOffer(Object error);

  /// No description provided for @failedToApply.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply: {error}'**
  String failedToApply(Object error);

  /// No description provided for @deliverySubmittedMsg.
  ///
  /// In en, this message translates to:
  /// **'Delivery submitted successfully ✅'**
  String get deliverySubmittedMsg;

  /// No description provided for @projectApprovedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Project approved and marked as completed ✅'**
  String get projectApprovedCompleted;

  /// No description provided for @noDownloadableFile.
  ///
  /// In en, this message translates to:
  /// **'No downloadable file available'**
  String get noDownloadableFile;

  /// No description provided for @downloadingFile.
  ///
  /// In en, this message translates to:
  /// **'Downloading: {fileName}'**
  String downloadingFile(Object fileName);

  /// No description provided for @downloadFailedError.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailedError(Object error);

  /// No description provided for @bidAmountJod.
  ///
  /// In en, this message translates to:
  /// **'Bid Amount (JOD)'**
  String get bidAmountJod;

  /// No description provided for @addMessageToOffer.
  ///
  /// In en, this message translates to:
  /// **'Add a message to your offer...'**
  String get addMessageToOffer;

  /// No description provided for @proposalOptional.
  ///
  /// In en, this message translates to:
  /// **'Proposal (Optional)'**
  String get proposalOptional;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @describeChangesNeeded.
  ///
  /// In en, this message translates to:
  /// **'Describe what changes are needed...'**
  String get describeChangesNeeded;

  /// No description provided for @freelancerProfile.
  ///
  /// In en, this message translates to:
  /// **'Freelancer Profile'**
  String get freelancerProfile;

  /// No description provided for @freelancerName.
  ///
  /// In en, this message translates to:
  /// **'Freelancer Name'**
  String get freelancerName;

  /// No description provided for @ratingStars.
  ///
  /// In en, this message translates to:
  /// **'Rating: {rating} ⭐'**
  String ratingStars(Object rating);

  /// No description provided for @plansForFreelancersOnly.
  ///
  /// In en, this message translates to:
  /// **'Plans are available for freelancers only.'**
  String get plansForFreelancersOnly;

  /// No description provided for @pleaseLoginToSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Please log in to subscribe'**
  String get pleaseLoginToSubscribe;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful! Subscription activated.'**
  String get paymentSuccessful;

  /// No description provided for @paymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentCancelled;

  /// No description provided for @paymentError.
  ///
  /// In en, this message translates to:
  /// **'Payment error: {error}'**
  String paymentError(Object error);

  /// No description provided for @noActiveSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No active subscriptions'**
  String get noActiveSubscriptions;

  /// No description provided for @pleaseFillAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields correctly'**
  String get pleaseFillAllRequiredFields;

  /// No description provided for @profileUpdatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedMsg;

  /// No description provided for @supportRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Support request submitted. We\'ll get back to you soon!'**
  String get supportRequestSubmitted;

  /// No description provided for @referralCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied: {code}'**
  String referralCodeCopied(Object code);

  /// No description provided for @acceptanceOfTerms.
  ///
  /// In en, this message translates to:
  /// **'Acceptance of Terms'**
  String get acceptanceOfTerms;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @userResponsibilities.
  ///
  /// In en, this message translates to:
  /// **'User Responsibilities'**
  String get userResponsibilities;

  /// No description provided for @projectsDeliverables.
  ///
  /// In en, this message translates to:
  /// **'Projects & Deliverables'**
  String get projectsDeliverables;

  /// No description provided for @paymentsFees.
  ///
  /// In en, this message translates to:
  /// **'Payments & Fees'**
  String get paymentsFees;

  /// No description provided for @disputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get disputes;

  /// No description provided for @termination.
  ///
  /// In en, this message translates to:
  /// **'Termination'**
  String get termination;

  /// No description provided for @limitationOfLiability.
  ///
  /// In en, this message translates to:
  /// **'Limitation of Liability'**
  String get limitationOfLiability;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @informationWeCollect.
  ///
  /// In en, this message translates to:
  /// **'1. Information We Collect'**
  String get informationWeCollect;

  /// No description provided for @howWeUseInformation.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Information'**
  String get howWeUseInformation;

  /// No description provided for @sharingThirdParties.
  ///
  /// In en, this message translates to:
  /// **'3. Sharing & Third Parties'**
  String get sharingThirdParties;

  /// No description provided for @dataRetention.
  ///
  /// In en, this message translates to:
  /// **'4. Data Retention'**
  String get dataRetention;

  /// No description provided for @securityPrivacy.
  ///
  /// In en, this message translates to:
  /// **'5. Security'**
  String get securityPrivacy;

  /// No description provided for @yourRights.
  ///
  /// In en, this message translates to:
  /// **'6. Your Rights'**
  String get yourRights;

  /// No description provided for @contactPrivacy.
  ///
  /// In en, this message translates to:
  /// **'7. Contact'**
  String get contactPrivacy;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @arabicLanguage.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabicLanguage;

  /// No description provided for @noApplicantsYet.
  ///
  /// In en, this message translates to:
  /// **'No applicants yet'**
  String get noApplicantsYet;

  /// No description provided for @pleaseEnterCompleteOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter complete OTP'**
  String get pleaseEnterCompleteOtp;

  /// No description provided for @otpResentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'OTP resent successfully'**
  String get otpResentSuccessfully;

  /// No description provided for @pleaseSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Please select a role'**
  String get pleaseSelectRole;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one category'**
  String get pleaseSelectCategory;

  /// No description provided for @pleaseEnterOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter OTP'**
  String get pleaseEnterOtp;

  /// No description provided for @termsConditionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditionsTitle;

  /// No description provided for @refundPolicy.
  ///
  /// In en, this message translates to:
  /// **'Refund Policy'**
  String get refundPolicy;

  /// No description provided for @onboardingTitle1New.
  ///
  /// In en, this message translates to:
  /// **'Connect Talent\nwith Opportunity'**
  String get onboardingTitle1New;

  /// No description provided for @onboardingTitle2New.
  ///
  /// In en, this message translates to:
  /// **'Seamless\nCollaboration'**
  String get onboardingTitle2New;

  /// No description provided for @onboardingTitle3New.
  ///
  /// In en, this message translates to:
  /// **'Secure & Smart\nPayments'**
  String get onboardingTitle3New;

  /// No description provided for @onboardingTitle4New.
  ///
  /// In en, this message translates to:
  /// **'Start Your\nJourney'**
  String get onboardingTitle4New;

  /// No description provided for @onboardingDesc1New.
  ///
  /// In en, this message translates to:
  /// **'Find the best freelancers for your project or discover exciting opportunities to showcase your skills.'**
  String get onboardingDesc1New;

  /// No description provided for @onboardingDesc2New.
  ///
  /// In en, this message translates to:
  /// **'Work together effortlessly with built-in tools for communication, file sharing, and project management.'**
  String get onboardingDesc2New;

  /// No description provided for @onboardingDesc3New.
  ///
  /// In en, this message translates to:
  /// **'Enjoy peace of mind with our escrow protection and milestone-based payment system.'**
  String get onboardingDesc3New;

  /// No description provided for @onboardingDesc4New.
  ///
  /// In en, this message translates to:
  /// **'Create your account and start your freelancing journey today.'**
  String get onboardingDesc4New;

  /// No description provided for @development.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get development;

  /// No description provided for @contentWriting.
  ///
  /// In en, this message translates to:
  /// **'Content Writing'**
  String get contentWriting;

  /// No description provided for @design.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get design;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @dataEntry.
  ///
  /// In en, this message translates to:
  /// **'Data Entry'**
  String get dataEntry;

  /// No description provided for @adminSupport.
  ///
  /// In en, this message translates to:
  /// **'Admin Support'**
  String get adminSupport;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusBidding.
  ///
  /// In en, this message translates to:
  /// **'Bidding'**
  String get statusBidding;

  /// No description provided for @statusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get statusPendingReview;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusRevisionRequested.
  ///
  /// In en, this message translates to:
  /// **'Revision Requested'**
  String get statusRevisionRequested;

  /// No description provided for @statusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get statusNotStarted;

  /// No description provided for @statusAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Payment'**
  String get statusAwaitingPayment;

  /// No description provided for @fixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get fixed;

  /// No description provided for @hourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get hourly;

  /// No description provided for @bidding.
  ///
  /// In en, this message translates to:
  /// **'Bidding'**
  String get bidding;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @postedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by'**
  String get postedBy;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @budgetRange.
  ///
  /// In en, this message translates to:
  /// **'Budget Range'**
  String get budgetRange;

  /// No description provided for @jod.
  ///
  /// In en, this message translates to:
  /// **'JOD'**
  String get jod;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjectsYet;

  /// No description provided for @yourProjectsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your projects will appear here'**
  String get yourProjectsWillAppearHere;

  /// No description provided for @welcomeBackName.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBackName(Object name);

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @popularCategories.
  ///
  /// In en, this message translates to:
  /// **'Popular Categories'**
  String get popularCategories;

  /// No description provided for @latestProjects.
  ///
  /// In en, this message translates to:
  /// **'Latest Projects'**
  String get latestProjects;

  /// No description provided for @findTopFreelancersFast.
  ///
  /// In en, this message translates to:
  /// **'Find top freelancers fast'**
  String get findTopFreelancersFast;

  /// No description provided for @postProjectGetOffers.
  ///
  /// In en, this message translates to:
  /// **'Post a project and get offers'**
  String get postProjectGetOffers;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategoriesAvailable;

  /// No description provided for @noProjectsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No projects available'**
  String get noProjectsAvailable;

  /// No description provided for @failedToLoadProjects.
  ///
  /// In en, this message translates to:
  /// **'Failed to load projects'**
  String get failedToLoadProjects;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a code to reset your password.'**
  String get forgotPasswordDesc;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @enterOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP code'**
  String get enterOtpCode;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code?'**
  String get didntReceiveCode;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new password for your account.'**
  String get resetPasswordDesc;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get savePassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get passwordUpdated;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordUppercase;

  /// No description provided for @passwordLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter'**
  String get passwordLowercase;

  /// No description provided for @passwordNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get passwordNumber;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters, 1 uppercase, 1 lowercase, 1 number'**
  String get passwordRequirements;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get oldestFirst;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @anyBudget.
  ///
  /// In en, this message translates to:
  /// **'Any Budget'**
  String get anyBudget;

  /// No description provided for @budgetLessThan50.
  ///
  /// In en, this message translates to:
  /// **'Up to 50 JOD'**
  String get budgetLessThan50;

  /// No description provided for @budget50To200.
  ///
  /// In en, this message translates to:
  /// **'50 – 200 JOD'**
  String get budget50To200;

  /// No description provided for @budgetAbove200.
  ///
  /// In en, this message translates to:
  /// **'200+ JOD'**
  String get budgetAbove200;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTime;

  /// No description provided for @anyTime.
  ///
  /// In en, this message translates to:
  /// **'Any Time'**
  String get anyTime;

  /// No description provided for @deliveryShort.
  ///
  /// In en, this message translates to:
  /// **'Up to 7 days'**
  String get deliveryShort;

  /// No description provided for @deliveryMedium.
  ///
  /// In en, this message translates to:
  /// **'8 – 30 days'**
  String get deliveryMedium;

  /// No description provided for @deliveryLong.
  ///
  /// In en, this message translates to:
  /// **'More than 30 days'**
  String get deliveryLong;

  /// No description provided for @freelancerApplicationWaitingClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Application sent'**
  String get freelancerApplicationWaitingClientTitle;

  /// No description provided for @freelancerApplicationWaitingClientBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the client to accept your application. You can submit work after you are assigned.'**
  String get freelancerApplicationWaitingClientBody;

  /// No description provided for @freelancerInvitePendingAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation pending'**
  String get freelancerInvitePendingAcceptTitle;

  /// No description provided for @freelancerInvitePendingAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'Please accept the client invitation to start work on this project.'**
  String get freelancerInvitePendingAcceptBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
