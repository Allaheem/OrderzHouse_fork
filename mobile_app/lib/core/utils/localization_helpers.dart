// ??? ????????
import '../../l10n/app_localizations.dart';

/// Helper class for localizing backend values like status, project type, etc.
class LocalizationHelpers {
  /// Convert project status string from backend to localized text
  static String localizeStatus(AppLocalizations l10n, String? status) {
    if (status == null || status.isEmpty) return l10n.naNotAvailable;

    switch (status.toLowerCase().replaceAll('_', '').replaceAll('-', '')) {
      case 'active':
        return l10n.statusActive;
      case 'bidding':
        return l10n.statusBidding;
      case 'pendingreview':
        return l10n.statusPendingReview;
      case 'completed':
        return l10n.statusCompleted;
      case 'pending':
        return l10n.statusPending;
      case 'inprogress':
        return l10n.statusInProgress;
      case 'cancelled':
      case 'canceled':
        return l10n.statusCancelled;
      case 'rejected':
        return l10n.statusRejected;
      case 'accepted':
        return l10n.statusAccepted;
      case 'open':
        return l10n.statusOpen;
      case 'closed':
        return l10n.statusClosed;
      case 'draft':
        return l10n.statusDraft;
      case 'expired':
        return l10n.statusExpired;
      case 'assigned':
        return l10n.statusAssigned;
      case 'delivered':
        return l10n.statusDelivered;
      case 'revisionrequested':
        return l10n.statusRevisionRequested;
      case 'notstarted':
        return l10n.statusNotStarted;
      case 'awaitingpayment':
        return l10n.statusAwaitingPayment;
      default:
        // Return the original status with first letter capitalized
        return status.isNotEmpty
            ? status[0].toUpperCase() +
                  status.substring(1).toLowerCase().replaceAll('_', ' ')
            : status;
    }
  }

  /// Convert project type string to localized text
  static String localizeProjectType(AppLocalizations l10n, String? type) {
    if (type == null || type.isEmpty) return l10n.naNotAvailable;

    switch (type.toLowerCase()) {
      case 'fixed':
        return l10n.fixed;
      case 'hourly':
        return l10n.hourly;
      case 'bidding':
        return l10n.bidding;
      default:
        return type;
    }
  }

  /// Convert category name to localized text (for common categories)
  static String localizeCategory(AppLocalizations l10n, String? category) {
    if (category == null || category.isEmpty) return l10n.naNotAvailable;

    switch (category.toLowerCase()) {
      case 'development':
        return l10n.development;
      case 'content writing':
      case 'contentwriting':
        return l10n.contentWriting;
      case 'design':
        return l10n.design;
      case 'marketing':
        return l10n.marketing;
      case 'data entry':
      case 'dataentry':
        return l10n.dataEntry;
      case 'admin support':
      case 'adminsupport':
        return l10n.adminSupport;
      default:
        // Return original name for categories not in our predefined list
        return category;
    }
  }
}
