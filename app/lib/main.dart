import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:grpc/grpc.dart';
import 'package:grpc_gen/grpc_gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final channelProvider = Provider.autoDispose<ClientChannel>((ref) {
  final channel = ClientChannel(
    'localhost',
    port: 50051,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(),
    ),
  );
  ref.onDispose(channel.shutdown);
  return channel;
});

final nameProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final greeterProvider = FutureProvider.autoDispose<String>((ref) async {
  final channel = ref.watch(channelProvider);
  final name = ref.watch(nameProvider);
  if (name.isEmpty) {
    return '';
  }
  final client = GreeterClient(channel);
  final response = await client.sayHello(HelloRequest(name: name),
      options: CallOptions(compression: const GzipCodec()));

  return response.message;
});

void main() {
  runApp(const MyApp());
}

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textController = useTextEditingController();
    return Scaffold(
        appBar: AppBar(title: const Text('Hello World')),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final greet = ref.watch(greeterProvider).valueOrNull ?? '';
                  return Text(greet);
                },
              ),
              const SizedBox(height: 32),
              Consumer(
                builder: (context, ref, child) {
                  return TextFormField(
                    controller: textController,
                    onEditingComplete: () {
                      ref
                          .read(nameProvider.notifier)
                          .update((state) => textController.text);
                    },
                  );
                },
              ),
            ],
          ),
        ));
  }
}
