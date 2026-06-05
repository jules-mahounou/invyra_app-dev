import 'package:flutter/material.dart';

import 'models/invitation_data.dart';
import 'mariage/template_elegance_doree.dart';
import 'mariage/template_midnight_romance.dart';
import 'anniversaire/template_fete_coloree.dart';
import 'anniversaire/template_neon_birthday.dart';
import 'bapteme/template_sacred_lilies.dart';
import 'bapteme/template_douceur_celeste.dart';
import 'soiree_vip/template_midnight_accra.dart';
import 'soiree_vip/template_golden_gala.dart';
import 'corporate/template_executive_summit.dart';
import 'corporate/template_african_tech.dart';

class TemplateResolver {
  // Résolution par class_name venant de la colonne Supabase event_templates.class_name
  // Quand un template est sélectionné, on passe son class_name ici
  // Pas besoin de modifier ce fichier quand on ajoute un template en base
  // — il suffit de renseigner class_name correctement dans Supabase

  static Widget resolve({
    required String? templateId,
    required String? className,
    required String eventType,
    required InvitationData data,
  }) {
    // Priorité 1 : résolution par class_name depuis Supabase
    if (className != null && className.trim().isNotEmpty) {
      return _buildByClassName(templateClassName: className.trim(), data: data);
    }

    // Priorité 2 : fallback par type d'événement si pas de class_name
    return _defaultForType(eventType: eventType, data: data);
  }

  static Widget preview({
    required String templateClassName,
    required String eventType,
  }) {
    final demoData = InvitationData(
      nomEvenement: _demoName(eventType),
      eventType: eventType,
      date: '15 juin 2025',
      heure: '18h00',
      lieu: 'Abidjan, Côte d\'Ivoire',
      nomCouple: eventType == 'mariage' ? 'Helena & Yamid' : null,
      message: 'Votre présence nous honorerait en ce jour si spécial.',
      customField1Label: eventType == 'anniversaire' ? 'Âge' : 'Thème',
      customField1Value: eventType == 'anniversaire' ? '30' : 'Premium Experience',
      customField2Label: eventType == 'corporate' ? 'Intervenant' : null,
      customField2Value: eventType == 'corporate' ? 'Amina Kone' : null,
    );
    return _buildByClassName(templateClassName: templateClassName, data: demoData);
  }

  static Widget _buildByClassName({
    required String templateClassName,
    required InvitationData data,
  }) {
    switch (templateClassName) {
      case 'TemplateEleganceDoree':
        return TemplateEleganceDoree(data: data);
      case 'TemplateMidnightRomance':
        return TemplateMidnightRomance(data: data);
      case 'TemplateFeteColoree':
        return TemplateFeteColoree(data: data);
      case 'TemplateNeonBirthday':
        return TemplateNeonBirthday(data: data);
      case 'TemplateSacredLilies':
        return TemplateSacredLilies(data: data);
      case 'TemplateDouceurCeleste':
        return TemplateDouceurCeleste(data: data);
      case 'TemplateMidnightAccra':
        return TemplateMidnightAccra(data: data);
      case 'TemplateGoldenGala':
        return TemplateGoldenGala(data: data);
      case 'TemplateExecutiveSummit':
        return TemplateExecutiveSummit(data: data);
      case 'TemplateAfricanTech':
        return TemplateAfricanTech(data: data);
      default:
        return TemplateEleganceDoree(data: data);
    }
  }

  static Widget _defaultForType({
    required String eventType,
    required InvitationData data,
  }) {
    switch (eventType) {
      case 'mariage':
        return TemplateEleganceDoree(data: data);
      case 'anniversaire':
        return TemplateFeteColoree(data: data);
      case 'bapteme':
        return TemplateSacredLilies(data: data);
      case 'soiree_vip':
        return TemplateGoldenGala(data: data);
      case 'corporate':
        return TemplateExecutiveSummit(data: data);
      default:
        return TemplateEleganceDoree(data: data);
    }
  }

  static String _demoName(String type) {
    switch (type) {
      case 'mariage':
        return 'Notre Mariage';
      case 'anniversaire':
        return 'Anniversaire de Kofi';
      case 'bapteme':
        return 'Baptême de Grace';
      case 'soiree_vip':
        return 'Soirée Exclusive';
      case 'corporate':
        return 'Summit Africain 2025';
      default:
        return 'Mon Événement';
    }
  }
}
