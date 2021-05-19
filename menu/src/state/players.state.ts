import {
  atom,
  selector,
  useRecoilState,
  useRecoilValue,
  useSetRecoilState,
} from "recoil";
import { debugData } from "../utils/debugLog";

enum VehicleStatus {
  Walking = "walking",
  Driving = "driving",
  Boat = "boating",
  Biking = "biking",
}

export interface PlayerData {
  health: number;
  vehicleStatus: VehicleStatus;
  id: number;
  distance: number;
  username: string;
}

export enum PlayerDataSort {
  IdJoinedFirst = "idJoinedFirst",
  IdJoinedLast = "idJoinedLast",
  DistanceClosest = "distanceClosest",
  DistanceFarthest = "distanceFarthest",
}

const playersState = {
  playerData: atom<PlayerData[]>({
    default: [],
    key: "playerStates",
  }),
  playerDetails: atom({
    default: null,
    key: 'playerDetails'
  }),
  playerSortType: atom<PlayerDataSort | null>({
    default: PlayerDataSort.IdJoinedFirst,
    key: "playerSortType",
  }),
  sortedAndFilteredPlayerData: selector({
    key: "sortedAndFilteredPlayerStates",
    get: ({ get }) => {
      const sortType: PlayerDataSort = get(playersState.playerSortType);
      const filteredValueInput = get(playersState.filterPlayerDataInput);
      const unfilteredPlayerStates = get(playersState.playerData);

      const formattedInput = filteredValueInput.trim().toLowerCase()

      const playerStates: PlayerData[] = filteredValueInput
        ? unfilteredPlayerStates.filter(
            (player) =>
              player.username
                .toLowerCase()
                .includes(formattedInput) ||
              player.id.toString().includes(formattedInput)
          )
        : unfilteredPlayerStates;

      switch (sortType) {
        case PlayerDataSort.DistanceClosest:
          return [...playerStates].sort((a, b) =>
            a.distance > b.distance ? 1 : -1
          );
        case PlayerDataSort.DistanceFarthest:
          return [...playerStates].sort((a, b) =>
            a.distance < b.distance ? 1 : -1
          );
        case PlayerDataSort.IdJoinedFirst:
          return [...playerStates].sort((a, b) => (a.id > b.id ? 1 : -1));
        case PlayerDataSort.IdJoinedLast:
          return [...playerStates].sort((a, b) => (a.id < b.id ? 1 : -1));
        default:
          return playerStates;
      }
    },
  }),
  filterPlayerDataInput: atom({
    key: "filterPlayerDataInput",
    default: "",
  }),
};

export const usePlayersState = () => useRecoilValue(playersState.playerData);

export const useSetPlayersState = () =>
  useSetRecoilState(playersState.playerData);

export const useSetPlayerFilter = () => useSetRecoilState(playersState.filterPlayerDataInput)

export const usePlayersSortedValue = () =>
  useRecoilValue(playersState.sortedAndFilteredPlayerData);

export const usePlayersSortBy = () =>
  useRecoilState(playersState.playerSortType);

export const usePlayersFilter = () =>
  useRecoilState(playersState.filterPlayerDataInput);

export const useFilteredSortedPlayers = (): PlayerData[] =>
  useRecoilValue(playersState.sortedAndFilteredPlayerData);

export const usePlayerDetails= (): PlayerData  =>
  useRecoilValue(playersState.playerDetails);

export const useSetPlayerDetails = () =>
  useSetRecoilState(playersState.playerDetails);

debugData<PlayerData[]>([
  {
    action: "setPlayerState",
    data: [
      {
        vehicleStatus: VehicleStatus.Walking,
        username: "Chip",
        id: 1,
        distance: 500,
        health: 80,
      },
      {
        vehicleStatus: VehicleStatus.Driving,
        username: "Taso",
        id: 2,
        distance: 500,
        health: 50,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Tabarra",
        id: 3,
        distance: 500,
        health: 10,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 4,
        distance: 500,
        health: 100,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 5,
        distance: 500,
        health: 70,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 6,
        distance: 500,
        health: 100,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 7,
        distance: 500,
        health: 40,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 8,
        distance: 500,
        health: 40,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 9,
        distance: 500,
        health: 40,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 10,
        distance: 500,
        health: 40,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 11,
        distance: 500,
        health: 40,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 12,
        distance: 500,
        health: 40,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 13,
        distance: 500,
        health: 40,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 14,
        distance: 500,
        health: 40,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 15,
        distance: 500,
        health: 40,
      },
      {
        vehicleStatus: VehicleStatus.Boat,
        username: "Death",
        id: 16,
        distance: 500,
        health: 40,
      },
    ],
  },
]);