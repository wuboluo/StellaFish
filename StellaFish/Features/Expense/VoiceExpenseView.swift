import SwiftUI

struct VoiceExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var speechService = SpeechService()
    @State private var showConfirm = false
    @State private var parsedExpenses: [ParsedExpense] = []
    @State private var pendingSave: [ExpenseRecord]? = nil
    @State private var shouldAutoParseOnStop = false
    @State private var parseAttempted = false
    private let parser = ExpenseParser()

    var onSave: ([ExpenseRecord]) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                transcriptArea

                recordButton

                Text(speechService.isRecording ? "正在录音…松开即可解析" : "长按说话，松开解析")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let error = speechService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Empty state after a parse attempt with no results
                if parseAttempted && parsedExpenses.isEmpty && !speechService.isRecording {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.bubble")
                            .foregroundStyle(.orange)
                        Text("没有识别到可记账内容，请重试或手动添加")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(24)
            .background(AppColors.background)
            .navigationTitle("语音记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .sheet(isPresented: $showConfirm, onDismiss: {
                if let records = pendingSave {
                    onSave(records)
                    dismiss()
                }
            }) {
                ExpenseConfirmView(parsed: parsedExpenses) { records in
                    pendingSave = records
                }
            }
            .onChange(of: speechService.isRecording) { _, nowRecording in
                if !nowRecording && shouldAutoParseOnStop {
                    shouldAutoParseOnStop = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        if !speechService.recognizedText.isEmpty {
                            parseAndContinue()
                        } else {
                            parseAttempted = true
                        }
                    }
                }
            }
        }
    }

    private var transcriptArea: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            if speechService.recognizedText.isEmpty {
                Text("说一句话，例如：\n午饭花了35元，打车15块")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(16)
            } else {
                Text(speechService.recognizedText)
                    .font(.body)
                    .padding(16)
            }
        }
        .frame(minHeight: 120)
    }

    private var recordButton: some View {
        ZStack {
            Circle()
                .fill(speechService.isRecording ? Color.red : AppColors.primary)
                .frame(width: 80, height: 80)
                .shadow(
                    color: (speechService.isRecording ? Color.red : AppColors.primary).opacity(0.4),
                    radius: 12, y: 6
                )
            Image(systemName: "mic.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
        }
        .scaleEffect(speechService.isRecording ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: speechService.isRecording)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !speechService.isRecording {
                        shouldAutoParseOnStop = false
                        parseAttempted = false
                        speechService.startRecording()
                    }
                }
                .onEnded { _ in
                    shouldAutoParseOnStop = true
                    speechService.stopRecording()
                }
        )
    }

    private func parseAndContinue() {
        let results = parser.parse(speechService.recognizedText)
        parseAttempted = true
        parsedExpenses = results
        if !results.isEmpty {
            showConfirm = true
        }
    }
}
