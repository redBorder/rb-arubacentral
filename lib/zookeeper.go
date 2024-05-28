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
	_, err = conn.Create(lockPath, []byte{}, 0, zk.WorldACL(zk.PermAll))
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
	newLockPath := lockPath + "/" + string(sessionIDBytes)
	log.Println("Creating lock:", newLockPath)
	_, err := z.Conn.Create(newLockPath, []byte{}, zk.FlagEphemeral, zk.WorldACL(zk.PermAll))
	if err != nil {
		log.Fatalf("Failed to create lock: %v", err)
	}
}

func (z *ZookeeperClient) ReleaseLock() {
	sessionID := z.Conn.SessionID()
	sessionIDBytes := []byte(strconv.FormatInt(int64(sessionID), 10))
	newLockPath := lockPath + "/" + string(sessionIDBytes)
	_, _, err := z.Conn.Get(newLockPath)
	if err != nil {
		return
	}
	err = z.Conn.Delete(newLockPath, -1)
	if err != nil {
		log.Fatalf("Failed to release lock: %v", err)
	}
}

func (z *ZookeeperClient) IsLocked() bool {
	children, _, err := z.Conn.Children(lockPath)
	if err != nil {
		return false
	}
	return len(children) > 0
}

func (z *ZookeeperClient) Close() {
	z.Conn.Close()
}
