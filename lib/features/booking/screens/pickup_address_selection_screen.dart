import 'package:flutter/material.dart';

import '../../addresses/models/saved_address.dart';
import '../../addresses/services/address_service.dart';
import '../../addresses/screens/address_form_screen.dart';

import 'choose_walk_screen.dart';
import 'booking_confirmation_screen.dart';
import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';

const Color pickupOrange = DojoWalkTheme.primary;
const Color pickupBackground = DojoWalkTheme.background;
const Color pickupText = DojoWalkTheme.text;
const Color pickupMuted = DojoWalkTheme.mutedText;

class PickupAddressSelectionScreen extends StatefulWidget {
  final WalkBookingType walkType;
  final Map<String, dynamic> schedule;
  final Map<String, dynamic> dogDetails;

  const PickupAddressSelectionScreen({
    super.key,
    required this.walkType,
    required this.schedule,
    required this.dogDetails,
  });

  @override
  State<PickupAddressSelectionScreen> createState() =>
      _PickupAddressSelectionScreenState();
}

class _PickupAddressSelectionScreenState
    extends State<PickupAddressSelectionScreen> {
  final AddressService _addressService = AddressService();

  String? _selectedAddressId;
  SavedAddress? _selectedAddress;

  bool _isContinuing = false;
  bool _isOpeningForm = false;

  String _addressText(SavedAddress address) {
    final parts = <String>[
      address.flatHouse,
      address.buildingSociety,
      address.area,
      address.landmark,
      address.city,
      address.pincode,
    ]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    final uniqueParts = <String>[];

    for (final part in parts) {
      if (!uniqueParts.contains(part)) {
        uniqueParts.add(part);
      }
    }

    return uniqueParts.join(', ');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _selectAddress(SavedAddress address) {
    setState(() {
      _selectedAddress = address;
      _selectedAddressId = address.id;
    });
  }

  Future<void> _addAddress() async {
    if (_isOpeningForm) return;

    setState(() => _isOpeningForm = true);

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AddressFormScreen(),
        ),
      );

      if (!mounted) return;

      // Address list will refresh through the service stream.
      setState(() {});
    } catch (e) {
      _showMessage(AppLocalizations.of(context).pickupOpenAddressFailed);
    } finally {
      if (mounted) {
        setState(() => _isOpeningForm = false);
      }
    }
  }

  Future<void> _continue() async {
    if (_isContinuing) return;

    final address = _selectedAddress;

    if (address == null || _selectedAddressId == null) {
      _showMessage(AppLocalizations.of(context).pickupSelectAddress);
      return;
    }

    final fullAddress = _addressText(address);

    if (fullAddress.isEmpty) {
      _showMessage(AppLocalizations.of(context).pickupAddressIncomplete);
      return;
    }

    setState(() => _isContinuing = true);

    try {
      final addressMap = <String, dynamic>{
        'addressId': address.id,
        'label': address.label,
        'flatHouse': address.flatHouse,
        'buildingSociety': address.buildingSociety,
        'address': [
          address.flatHouse,
          address.buildingSociety,
        ]
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .join(', '),
        'area': address.area,
        'landmark': address.landmark,
        'city': address.city,
        'pincode': address.pincode,
        'pickupInstructions': address.pickupInstructions,
        'isDefault': address.isDefault,
      };

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            walkType: widget.walkType,
            dogDetails: widget.dogDetails,
            pickupAddress: addressMap,
            schedule: widget.schedule,
          ),
        ),
      );
    } catch (e) {
      _showMessage(AppLocalizations.of(context).pickupOpenReviewFailed);
    } finally {
      if (mounted) {
        setState(() => _isContinuing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pickupBackground,
      appBar: AppBar(
        backgroundColor: pickupOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).pickupAddressTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<SavedAddress>>(
          stream: _addressService.watchAddresses(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_off_outlined,
                        size: 48,
                        color: pickupOrange,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context).pickupLoadAddressesFailed,
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: pickupMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => setState(() {}),
                        child: Text(AppLocalizations.of(context).pickupRetry),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: pickupOrange,
                ),
              );
            }

            final addresses = snapshot.data ?? [];

            // Automatically select the default address, but only when
            // the customer has not already selected another address.
            if (addresses.isNotEmpty &&
                (_selectedAddressId == null ||
                    !addresses.any(
                      (item) => item.id == _selectedAddressId,
                    ))) {
              final defaults = addresses.where(
                (item) => item.isDefault,
              );

              final defaultAddress =
                  defaults.isNotEmpty ? defaults.first : null;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                if (_selectedAddressId == null ||
                    !addresses.any(
                      (item) => item.id == _selectedAddressId,
                    )) {
                  final currentDefault = defaultAddress ?? addresses.first;
                  _selectAddress(currentDefault);
                }
              });
            }

            return Column(
              children: [
                Expanded(
                  child: addresses.isEmpty
                      ? _emptyAddresses()
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(
                              AppLocalizations.of(context).pickupPrompt,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: pickupText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context).pickupIntro,
                              style: TextStyle(
                                color: pickupMuted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ...addresses.map((address) {
                              final selected =
                                  _selectedAddressId == address.id;

                              final fullAddress = _addressText(address);

                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => _selectAddress(address),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFFFFE9D6)
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(18),
                                      border: Border.all(
                                        color: selected
                                            ? pickupOrange
                                            : const Color(0xFFF0E2D5),
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? pickupOrange
                                                : pickupBackground,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Icon(
                                            Icons.location_on_outlined,
                                            color: selected
                                                ? Colors.white
                                                : pickupOrange,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      address.label
                                                              .trim()
                                                              .isEmpty
                                                          ? AppLocalizations.of(context).pickupSavedAddress
                                                          : address.label,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: pickupText,
                                                      ),
                                                    ),
                                                  ),
                                                  if (address.isDefault)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: const Color(
                                                          0xFFE5F5E8,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Text(
                                                        AppLocalizations.of(context).pickupDefaultBadge,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Color(
                                                            0xFF218838,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 7),
                                              Text(
                                                fullAddress.isEmpty
                                                    ? 'Address details missing'
                                                    : fullAddress,
                                                style: const TextStyle(
                                                  color: pickupMuted,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          selected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: selected
                                              ? pickupOrange
                                              : pickupMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            OutlinedButton.icon(
                              onPressed:
                                  _isOpeningForm ? null : _addAddress,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: pickupOrange,
                                side: const BorderSide(
                                  color: pickupOrange,
                                ),
                                minimumSize:
                                    const Size.fromHeight(48),
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(
                                _isOpeningForm
                                    ? AppLocalizations.of(context).pickupOpening
                                    : AppLocalizations.of(context).pickupAddAnotherAddress,
                              ),
                            ),
                          ],
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFF0E2D5),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed:
                              _isContinuing ? null : _continue,
                          style: FilledButton.styleFrom(
                            backgroundColor: pickupOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isContinuing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context).pickupContinueReview,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed:
                            _isOpeningForm ? null : _addAddress,
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: Text(AppLocalizations.of(context).pickupAddNewAddress),
                        style: TextButton.styleFrom(
                          foregroundColor: pickupOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyAddresses() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 45),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF0E2D5),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 64,
                color: pickupOrange,
              ),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).pickupEmptyTitle,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: pickupText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).pickupEmptyBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pickupMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isOpeningForm ? null : _addAddress,
          style: FilledButton.styleFrom(
            backgroundColor: pickupOrange,
            minimumSize: const Size.fromHeight(52),
          ),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: Text(
            _isOpeningForm ? AppLocalizations.of(context).pickupOpening : AppLocalizations.of(context).pickupAddAddress,
          ),
        ),
      ],
    );
  }
}
