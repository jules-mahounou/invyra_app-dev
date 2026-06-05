import 'package:flutter/material.dart';

class EventModel {
  final String id;
  final String userId;
  final String? templateId;
  final String? subscriptionId;
  final String name;
  final String eventType;
  final String? customType;
  final String description;
  final DateTime? eventDate;
  final String place;
  final double? placeLat;
  final double? placeLng;
  final String? logoUrl;
  final String status;
  final String sendChannel;
  final int? guestQuota;
  final String? shareToken;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  
  // Statistiques issues des colonnes natives de la table events
  final int guestsCount;
  final int invitationsSent;
  final int invitationsViewed;
  final int guestsConfirmed;

  // Calcul dérivé pour les absents (Total envoyés/répondus - Confirmés)
  // Note: Si le besoin d'un compte précis basé sur les refus se fait sentir,
  // il sera calculé via une requête d'agrégation ou stocké dans la metadata.
  final int guestsDeclined;

  // Champs personnalisés stockés dans la colonne JSONB metadata
  final String? customField1Label;
  final String? customField1Value;
  final String? customField2Label;
  final String? customField2Value;

  EventModel({
    required this.id,
    required this.userId,
    this.templateId,
    this.subscriptionId,
    required this.name,
    required this.eventType,
    this.customType,
    required this.description,
    this.eventDate,
    required this.place,
    this.placeLat,
    this.placeLng,
    this.logoUrl,
    required this.status,
    required this.sendChannel,
    this.guestQuota,
    this.shareToken,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublished,
    required this.guestsCount,
    required this.invitationsSent,
    required this.invitationsViewed,
    required this.guestsConfirmed,
    required this.guestsDeclined,
    this.customField1Label,
    this.customField1Value,
    this.customField2Label,
    this.customField2Value,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    final rawMetadata = map['metadata'];
    final Map<String, dynamic> metadata = rawMetadata is Map ? Map<String, dynamic>.from(rawMetadata) : {};

    final sent = _parseInt(map['invitations_sent']);
    final confirmed = _parseInt(map['guests_confirmed']);
    // Estimation des absents basée sur les invitations envoyées qui ne sont pas confirmées
    final estimatedDeclined = (sent > confirmed) ? (sent - confirmed) : 0;

    return EventModel(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      templateId: map['template_id'] as String?,
      subscriptionId: map['subscription_id'] as String?,
      name: map['name'] as String? ?? 'Événement',
      eventType: map['event_type'] as String? ?? 'mariage',
      customType: map['custom_type'] as String?,
      description: map['description'] as String? ?? 'Aucune description pour le moment.',
      eventDate: map['event_date'] != null ? DateTime.parse(map['event_date'] as String).toLocal() : null,
      place: map['place'] as String? ?? 'Lieu non défini',
      placeLat: map['place_lat'] != null ? (map['place_lat'] as num).toDouble() : null,
      placeLng: map['place_lng'] != null ? (map['place_lng'] as num).toDouble() : null,
      logoUrl: map['logo_url'] as String?,
      status: map['status'] as String? ?? 'a_venir',
      sendChannel: map['send_channel'] as String? ?? 'whatsapp',
      guestQuota: map['guest_quota'] as int?,
      shareToken: map['share_token'] as String?,
      closedAt: map['closed_at'] != null ? DateTime.parse(map['closed_at'] as String).toLocal() : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String).toLocal() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String).toLocal() : DateTime.now(),
      isPublished: map['is_published'] as bool? ?? false,
      guestsCount: _parseInt(map['guests_count']),
      invitationsSent: sent,
      invitationsViewed: _parseInt(map['invitations_viewed']),
      guestsConfirmed: confirmed,
      guestsDeclined: estimatedDeclined,
      customField1Label: metadata['customField1Label'] as String?,
      customField1Value: metadata['customField1Value'] as String?,
      customField2Label: metadata['customField2Label'] as String?,
      customField2Value: metadata['customField2Value'] as String?,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;
  
  bool get hasCustomField1 => 
      customField1Label != null && customField1Label!.trim().isNotEmpty && 
      customField1Value != null && customField1Value!.trim().isNotEmpty;
      
  bool get hasCustomField2 => 
      customField2Label != null && customField2Label!.trim().isNotEmpty && 
      customField2Value != null && customField2Value!.trim().isNotEmpty;
}