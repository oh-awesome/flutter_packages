import fs from '@ohos.file.fs';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { Result, FileSelectorApiCodec} from './GeneratedFileSelectorApi'
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { AbilityPluginBinding } from
  '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import ArrayList from '@ohos.util.ArrayList';

const TAG = 'FileSelector';
export class FileSelector {

  binding: AbilityPluginBinding;
  // 保存通道引用，供 dispose() 注销 handler 时使用
  private channel: BasicMessageChannel<ESObject> | null = null;

  constructor(binding: AbilityPluginBinding) {
    this.binding = binding;
  }

  async openFileByPath(path: string, result: Result<number>): Promise<void> {
    try {
      let file = await fs.open(path);
      result.success(file.fd);
    } catch (err) {
      Log.e(TAG, 'open file failed with err: ' + err);
      result.error(new Error('Failed to read file'));
    }
  }

  static getCodec(): MessageCodec<ESObject> {
    return FileSelectorApiCodec.INSTANCE;
  }

  setup(binaryMessenger: BinaryMessenger, abilityPluginBinding: AbilityPluginBinding): void {
    let api = this;
    {
      this.binding = abilityPluginBinding;
      const channel: BasicMessageChannel<ESObject> = new BasicMessageChannel<ESObject>(
        binaryMessenger, 'dev.flutter.FileSelectorApi.openFileByPath', FileSelector.getCodec());
      this.channel = channel;
      channel.setMessageHandler({
        onMessage(msg: ESObject, reply: Reply<ESObject>): void {
          Log.d(TAG, 'onMessage reply:' + reply)
          const wrapped: Array<ESObject> = new Array<ESObject>();
          const args: Array<ESObject> = msg as Array<ESObject>;
          const path = args[0] as string;
          const resultCallback: Result<number> = new ResultBuilder((result: number): void => {
            wrapped.push(result);
            reply.reply(wrapped);
          },(error: Error): void => {
            const wrappedError: ArrayList<ESObject> = msg.wrapError(error);
            reply.reply(wrappedError);
          })
          api.openFileByPath(path, resultCallback);
        }
      });
    }
  }

  // 注销通道 handler，切断闭包对 FileSelector 实例的引用链（对齐 CameraPlugin detach 的防御性释
  // 放）
  dispose(): void {
    if (this.channel != null) {
      this.channel.setMessageHandler(null);
      this.channel = null;
    }
  }
}

class ResultBuilder{
  success : (result: number)=>void
  error: (error: Error) =>void

  constructor(success:ESObject , error:ESObject) {
    this.success = success
    this.error = error
  }
}