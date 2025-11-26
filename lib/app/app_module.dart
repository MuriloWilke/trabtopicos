import 'package:flutter_modular/flutter_modular.dart';
import 'core/services/ai_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/storage_service.dart';
import 'models/produto.dart';
import 'models/unidade.dart';
import 'screens/login_screen.dart';
import 'screens/unidade_list_screen.dart';
import 'screens/unidade_detail_screen.dart';
import 'screens/produto_edit_screen.dart';

class AppModule extends Module {
  @override
  void binds(i) {
    i.addLazySingleton(AuthService.new);
    i.addLazySingleton(StorageService.new);
    i.addLazySingleton(AiService.new);
  }

  @override
  void routes(r) {
    r.child('/', child: (context) => const LoginScreen());
    r.child('/unidades', child: (context) => const UnidadeListScreen());

    r.child('/unidade-detail', child: (context) => UnidadeDetailScreen(unidade: r.args.data as Unidade));

    r.child('/produto-edit', child: (context) {
      final args = r.args.data as Map<String, dynamic>;
      return ProdutoEditScreen(
        produto: args['produto'] as Produto,
        isVistoriaReview: args['isVistoria'] ?? false,
        camposAlteradosPelaIA: args['camposAlterados'] ?? [],
      );
    });
  }
}