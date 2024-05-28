package lib

import (
	"log"
	"strconv"
	"time"

	"github.com/samuel/go-zookeeper/zk"
)

const (
	lockPath = "/rb-arubacentral/lock"
	defPath  = "/rb-arubacentral"
)

type ZookeeperClient struct {
	Conn *zk.Conn
}

func NewZookeeperClient(servers []string) (*ZookeeperClient, error) {
	conn, _, err := zk.Connect(servers, time.Second)
	if err != nil {
		return nil, err
	}
	_, err = conn.Create(defPath, []byte{}, 0, zk.WorldACL(zk.PermAll))
	if err != nil && err != zk.ErrNodeExists {
		conn.Close()
		return nil, err
	}
	return &ZookeeperClient{Conn: conn}, nil
}

func (z *ZookeeperClient) Get(path string) ([]byte, error) {
	data, _, err := z.Conn.Get(path)
	return data, err
}

func (z *ZookeeperClient) Delete(path string) error {
	return z.Conn.Delete(path, -1)
}

func (z *ZookeeperClient) Lock() {
	sessionID := z.Conn.SessionID()
	sessionIDBytes := []byte(strconv.FormatInt(int64(sessionID), 10))
	_, err := z.Conn.Create(lockPath, sessionIDBytes, zk.FlagEphemeral, zk.WorldACL(zk.PermAll))
	if err != nil {
		log.Fatalf("Failed to create lock: %v", err)
	}
}

func (z *ZookeeperClient) ReleaseLock() {
	if err := z.Delete(lockPath); err != nil {
		log.Fatalf("Failed to release lock: %v", err)
	}
}

func (z *ZookeeperClient) IsLocked() bool {
	data, err := z.Get(lockPath)
	if err != nil {
		return false
	}
	return len(data) > 0
}

func (z *ZookeeperClient) Close() {
	z.Conn.Close()
}
