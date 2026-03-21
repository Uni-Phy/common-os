import { CoreMessage, generateId, Message } from "ai";
import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";
import { BenchmarkRun, KnowledgeTopic, PresetQuestion, ResearchTopic } from "@/types/modules";

const DEFAULT_PRESET_QUESTIONS: PresetQuestion[] = [
  { id: "p1", category: "quantum physics", content: "Explain quantum entanglement like I am 12, then add a rigorous version with equations and real-world applications." },
  { id: "p2", category: "spirituality", content: "Compare mindfulness, Vedanta, and Stoicism on handling anxiety and uncertainty, with practical daily exercises." },
  { id: "p3", category: "ai", content: "What are the practical trade-offs between RAG, fine-tuning, and agent workflows for building a local AI assistant?" },
  { id: "p4", category: "history", content: "Give a timeline of the 20th century’s most important turning points and explain how they shaped today’s geopolitics." },
  { id: "p5", category: "pop culture", content: "Analyze how memes, streaming platforms, and fandom culture influence public opinion and modern identity." },
  { id: "p6", category: "science + philosophy", content: "Where do modern neuroscience and philosophical ideas of consciousness agree and disagree?" },
  { id: "p7", category: "future trends", content: "What are the most likely social and economic changes from AI adoption over the next 10 years?" },
  { id: "p8", category: "mythology + meaning", content: "Compare archetypes in Greek mythology, Hindu epics, and modern superhero films." },
];

interface ChatSession {
  messages: Message[];
  createdAt: string;
}

interface State {
  base64Images: string[] | null;
  chats: Record<string, ChatSession>;
  currentChatId: string | null;
  selectedModel: string | null;
  userName: string | "Anonymous";
  isDownloading: boolean;
  downloadProgress: number;
  downloadingModel: string | null;
  presetQuestions: PresetQuestion[];
  knowledgeTopics: KnowledgeTopic[];
  researchTopics: ResearchTopic[];
  benchmarkRuns: BenchmarkRun[];
}

interface Actions {
  setBase64Images: (base64Images: string[] | null) => void;
  setCurrentChatId: (chatId: string) => void;
  setSelectedModel: (selectedModel: string) => void;
  getChatById: (chatId: string) => ChatSession | undefined;
  getMessagesById: (chatId: string) => Message[];
  saveMessages: (chatId: string, messages: Message[]) => void;
  handleDelete: (chatId: string, messageId?: string) => void;
  setUserName: (userName: string) => void;
  startDownload: (modelName: string) => void;
  stopDownload: () => void;
  setDownloadProgress: (progress: number) => void;
  addKnowledgeTopic: (topic: Omit<KnowledgeTopic, "id" | "createdAt">) => void;
  removeKnowledgeTopic: (id: string) => void;
  addResearchTopic: (topic: Omit<ResearchTopic, "id" | "updatedAt">) => void;
  updateResearchTopic: (id: string, updates: Partial<ResearchTopic>) => void;
  removeResearchTopic: (id: string) => void;
  addBenchmarkRun: (run: Omit<BenchmarkRun, "id" | "createdAt">) => void;
  removeBenchmarkRun: (id: string) => void;
}

const useChatStore = create<State & Actions>()(
  persist(
    (set, get) => ({
      base64Images: null,
      chats: {},
      currentChatId: null,
      selectedModel: null,
      userName: "Anonymous",
      isDownloading: false,
      downloadProgress: 0,
      downloadingModel: null,
      presetQuestions: DEFAULT_PRESET_QUESTIONS,
      knowledgeTopics: [],
      researchTopics: [],
      benchmarkRuns: [],

      setBase64Images: (base64Images) => set({ base64Images }),
      setUserName: (userName) => set({ userName }),

      setCurrentChatId: (chatId) => set({ currentChatId: chatId }),
      setSelectedModel: (selectedModel) => set({ selectedModel }),
      getChatById: (chatId) => {
        const state = get();
        return state.chats[chatId];
      },
      getMessagesById: (chatId) => {
        const state = get();
        return state.chats[chatId]?.messages || [];
      },
      saveMessages: (chatId, messages) => {
        set((state) => {
          const existingChat = state.chats[chatId];

          return {
            chats: {
              ...state.chats,
              [chatId]: {
                messages: [...messages],
                createdAt: existingChat?.createdAt || new Date().toISOString(),
              },
            },
          };
        });
      },
      handleDelete: (chatId, messageId) => {
        set((state) => {
          const chat = state.chats[chatId];
          if (!chat) return state;

          // If messageId is provided, delete specific message
          if (messageId) {
            const updatedMessages = chat.messages.filter(
              (message) => message.id !== messageId
            );
            return {
              chats: {
                ...state.chats,
                [chatId]: {
                  ...chat,
                  messages: updatedMessages,
                },
              },
            };
          }

          // If no messageId, delete the entire chat
          const { [chatId]: _, ...remainingChats } = state.chats;
          return {
            chats: remainingChats,
          };
        });
      },

      startDownload: (modelName) =>
        set({ isDownloading: true, downloadingModel: modelName, downloadProgress: 0 }),
      stopDownload: () =>
        set({ isDownloading: false, downloadingModel: null, downloadProgress: 0 }),
      setDownloadProgress: (progress) => set({ downloadProgress: progress }),
      addKnowledgeTopic: (topic) =>
        set((state) => ({
          knowledgeTopics: [
            {
              id: generateId(),
              createdAt: new Date().toISOString(),
              ...topic,
            },
            ...state.knowledgeTopics,
          ],
        })),
      removeKnowledgeTopic: (id) =>
        set((state) => ({
          knowledgeTopics: state.knowledgeTopics.filter((t) => t.id !== id),
        })),
      addResearchTopic: (topic) =>
        set((state) => ({
          researchTopics: [
            {
              id: generateId(),
              updatedAt: new Date().toISOString(),
              ...topic,
            },
            ...state.researchTopics,
          ],
        })),
      updateResearchTopic: (id, updates) =>
        set((state) => ({
          researchTopics: state.researchTopics.map((t) =>
            t.id === id ? { ...t, ...updates, updatedAt: new Date().toISOString() } : t
          ),
        })),
      removeResearchTopic: (id) =>
        set((state) => ({
          researchTopics: state.researchTopics.filter((t) => t.id !== id),
        })),
      addBenchmarkRun: (run) =>
        set((state) => ({
          benchmarkRuns: [
            {
              id: generateId(),
              createdAt: new Date().toISOString(),
              ...run,
            },
            ...state.benchmarkRuns,
          ],
        })),
      removeBenchmarkRun: (id) =>
        set((state) => ({
          benchmarkRuns: state.benchmarkRuns.filter((r) => r.id !== id),
        })),
    }),
    {
      name: "nextjs-ollama-ui-state",
      version: 2,
      migrate: (persistedState: any, version) => {
        if (version < 2) {
          return {
            ...persistedState,
            presetQuestions: DEFAULT_PRESET_QUESTIONS,
          };
        }
        return persistedState;
      },
      partialize: (state) => ({
        chats: state.chats,
        currentChatId: state.currentChatId,
        selectedModel: state.selectedModel,
        userName: state.userName,
        knowledgeTopics: state.knowledgeTopics,
        researchTopics: state.researchTopics,
        benchmarkRuns: state.benchmarkRuns,
      }),
    }
  )
);

export default useChatStore;