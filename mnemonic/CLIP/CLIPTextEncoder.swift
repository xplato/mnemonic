import Foundation
import OnnxRuntimeBindings
import Tokenizers

/// Wraps the ONNX Runtime text session + BPE tokenizer for CLIP text encoding.
final class CLIPTextEncoder: @unchecked Sendable {

    nonisolated(unsafe) private let session: ORTSession
    private nonisolated let tokenizer: any Tokenizer
    private nonisolated let outputName: String
    private nonisolated let maxLength = 77

    nonisolated init(modelPath: URL, tokenizerFolder: URL) async throws {
        let env = try ORTEnv(loggingLevel: .warning)

        // CPU-only for text model (small, fast, avoids CoreML dynamic shape issues)
        self.session = try ORTSession(
            env: env,
            modelPath: modelPath.path,
            sessionOptions: nil
        )

        // Load BPE tokenizer from local folder
        self.tokenizer = try await AutoTokenizer.from(modelFolder: tokenizerFolder)

        let outputNames = try session.outputNames()
        self.outputName = outputNames.first ?? "text_embeds"
    }

    /// Encode text query → normalized [512] embedding.
    nonisolated func encode(text: String) throws -> [Float] {
        // Tokenize
        let encoded = tokenizer(text)

        // Pad/truncate to 77 tokens
        var inputIds = encoded.map { Int32($0) }
        if inputIds.count > maxLength {
            // Keep start tokens, truncate middle, keep last (EOS)
            let eos = inputIds.last!
            inputIds = Array(inputIds.prefix(maxLength - 1)) + [eos]
        }
        var attentionMask = Array(repeating: Int32(1), count: inputIds.count)

        // Pad to maxLength
        while inputIds.count < maxLength {
            inputIds.append(0)
            attentionMask.append(0)
        }

        // Create tensors
        let idsData = inputIds.withUnsafeBufferPointer { Data(buffer: $0) }
        let maskData = attentionMask.withUnsafeBufferPointer { Data(buffer: $0) }

        let idsTensor = try ORTValue(
            tensorData: NSMutableData(data: idsData),
            elementType: .int32,
            shape: [1, NSNumber(value: maxLength)]
        )
        let maskTensor = try ORTValue(
            tensorData: NSMutableData(data: maskData),
            elementType: .int32,
            shape: [1, NSNumber(value: maxLength)]
        )

        // Discover input names
        let inputNames = try session.inputNames()
        var inputs: [String: ORTValue] = [:]
        for name in inputNames {
            if name.contains("input_id") || name == "input_ids" {
                inputs[name] = idsTensor
            } else if name.contains("attention") || name == "attention_mask" {
                inputs[name] = maskTensor
            }
        }

        // Fallback if name discovery didn't match
        if inputs.isEmpty {
            inputs = ["input_ids": idsTensor, "attention_mask": maskTensor]
        }

        let outputs = try session.run(
            withInputs: inputs,
            outputNames: Set([outputName]),
            runOptions: nil
        )

        guard let output = outputs[outputName] else {
            throw CLIPError.missingOutput(outputName)
        }

        let outputData = try output.tensorData() as Data
        var embedding = outputData.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }

        if embedding.count > 512 {
            embedding = Array(embedding.prefix(512))
        }

        return CLIPImageEncoder.l2Normalize(embedding)
    }
}
