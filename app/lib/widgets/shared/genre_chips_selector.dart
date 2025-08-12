import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/kid_profile_constants.dart';
import '../../generated/app_localizations.dart';

class GenreChipsSelector extends StatelessWidget {
  final List<String> selectedGenres;
  final ValueChanged<List<String>> onGenresChanged;

  const GenreChipsSelector({
    super.key,
    required this.selectedGenres,
    required this.onGenresChanged,
  });

  String _getLocalizedGenreName(BuildContext context, String genre) {
    final l10n = AppLocalizations.of(context)!;
    switch (genre) {
      case 'adventure':
        return l10n.genreAdventure;
      case 'fantasy':
        return l10n.genreFantasy;
      case 'friendship':
        return l10n.genreFriendship;
      case 'family':
        return l10n.genreFamily;
      case 'animals':
        return l10n.genreAnimals;
      case 'magic':
        return l10n.genreMagic;
      case 'space':
        return l10n.genreSpace;
      case 'underwater':
        return l10n.genreUnderwater;
      case 'forest':
        return l10n.genreForest;
      case 'fairy_tale':
        return l10n.genreFairyTale;
      case 'superhero':
        return l10n.genreSuperhero;
      case 'dinosaurs':
        return l10n.genreDinosaurs;
      case 'pirates':
        return l10n.genrePirates;
      case 'princess':
        return l10n.genrePrincess;
      case 'dragons':
        return l10n.genreDragons;
      case 'robots':
        return l10n.genreRobots;
      case 'mystery':
        return l10n.genreMystery;
      case 'funny':
        return l10n.genreFunny;
      case 'educational':
        return l10n.genreEducational;
      case 'bedtime':
        return l10n.genreBedtime;
      default:
        return genre;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: KidProfileConstants.storyGenres.map((genre) {
        final isSelected = selectedGenres.contains(genre);
        final displayName = _getLocalizedGenreName(context, genre);
        
        return GestureDetector(
          onTap: () {
            final newGenres = List<String>.from(selectedGenres);
            if (isSelected) {
              newGenres.remove(genre);
            } else {
              newGenres.add(genre);
            }
            onGenresChanged(newGenres);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.secondary : AppColors.lightGrey,
                width: 2,
              ),
            ),
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}