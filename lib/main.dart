import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_conch_plugin/annotation/patch_scope.dart';
import 'package:flutter_conch_plugin/conch_dispatch.dart';
import 'package:pokedex/app.dart';
import 'package:pokedex/core/network.dart';
import 'package:pokedex/data/repositories/item_repository.dart';
import 'package:pokedex/data/repositories/pokemon_repository.dart';
import 'package:pokedex/data/source/github/github_datasource.dart';
import 'package:pokedex/data/source/local/local_datasource.dart';
import 'package:pokedex/states/theme/theme_cubit.dart';
import 'package:pokedex/states/item/item_bloc.dart';
import 'package:pokedex/states/pokemon/pokemon_bloc.dart';

bool useConch = false;

@PatchScope()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (useConch) {
    var source = await rootBundle.load('assets/conch_build/patch_dat/conch_result.dat');
    ConchDispatch.instance.loadByteSource(source);
    // ConchDispatch.instance.setLogger(LogLevel.Debug);
    await ConchDispatch.instance.callStaticFun(library: 'package:pokedex/main.dart', funcName: 'mainInner');
    return;
  }

  await mainInner();
}

mainInner() async {
  await LocalDataSource.initialize();

  runApp(
    MultiRepositoryProvider(
      providers: [

        ///
        /// Services
        ///
        RepositoryProvider<NetworkManager>(
          create: (context) => NetworkManager(),
        ),

        ///
        /// Data sources
        ///
        RepositoryProvider<LocalDataSource>(
          create: (context) => LocalDataSource(),
        ),
        RepositoryProvider<GithubDataSource>(
          create: (context) => GithubDataSource(context.read<NetworkManager>()),
        ),

        ///
        ///
        /// Repositories
        ///
        RepositoryProvider<PokemonRepository>(
          create: (context) =>
              PokemonDefaultRepository(
                localDataSource: context.read<LocalDataSource>(),
                githubDataSource: context.read<GithubDataSource>(),
              ),
        ),

        RepositoryProvider<ItemRepository>(
          create: (context) =>
              ItemDefaultRepository(
                localDataSource: context.read<LocalDataSource>(),
                githubDataSource: context.read<GithubDataSource>(),
              ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [

          ///
          /// BLoCs
          ///
          BlocProvider<PokemonBloc>(
            create: (context) => PokemonBloc(context.read<PokemonRepository>()),
          ),
          BlocProvider<ItemBloc>(
            create: (context) => ItemBloc(context.read<ItemRepository>()),
          ),

          ///
          /// Theme Cubit
          ///
          BlocProvider<ThemeCubit>(
            create: (context) => ThemeCubit(),
          )
        ],
        child: PokedexApp(),
      ),
    ),
  );
}
