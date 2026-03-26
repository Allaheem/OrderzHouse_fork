// ??? ????????
/// Response from POST /stripe/create-checkout-session.
/// Matches web: { free: true } OR { url: "https://checkout.stripe.com/..." }
class CreateCheckoutResult {
  final bool free;
  final String? url;

  const CreateCheckoutResult({this.free = false, this.url});

  bool get hasCheckoutUrl => url != null && url!.isNotEmpty;
}
